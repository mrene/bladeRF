#include <stdio.h>
#include <pthread.h>
#include "libbladeRF.h"

#include <thread>
#include <iostream>
#include <sstream>
#include <fstream>
#include <iomanip>
#include <vector>
#include <future>

#include <cstdio>
#include <assert.h>

#include <string.h>

using std::cerr;
using std::cout;

typedef enum bladerf_fpga_mux {
    BLADERF_RX_MUX_NORMAL = 0,
    BLADERF_RX_MUX_12BIT_COUNTER,
    BLADERF_RX_MUX_32BIT_COUNTER,
    BLADERF_RX_MUX_FFT,
    BLADERF_RX_MUX_DIGITAL_LOOPBACK
} bladerf_fpga_mux_t;

static int bladerf_set_fpga_rx_mux(struct bladerf *dev, bladerf_fpga_mux_t mux) {
    uint32_t config_gpio;
    int status;

    if ((status = bladerf_config_gpio_read(dev, &config_gpio))) {
        return status;
    }

    // rx_mux_sel is a 3-bit value starting at bit 8
    // clear value
    config_gpio &= ~((1 << 8) | (1 << 9) | (1 << 10));
    // set value
    config_gpio |= mux << 8;

    return bladerf_config_gpio_write(dev, config_gpio);
}

static void data_dump(uint32_t *data, size_t samples) {
  cout << "Buffer start\n";
  // cout << std::setw(4) << std::hex << std::setfill('0');
  for (size_t i = 0; i < samples; i += 2) {
    // cout << std::dec << (int16_t)data[i] << " " << (int16_t)data[i+1] << "\n";
     cout << std::setw(4) << std::setfill('0') << std::hex << (int16_t)data[i] << " "
	  << std::setw(4) << std::setfill('0') << std::hex << (int16_t)data[i+1] << "\n";
  }
  cout << "Buffer end\n";
}

static int error_check(int status) {
    if (status) {
        throw std::runtime_error(bladerf_strerror(status));
    }

    return status;
}

struct buffer_holder {
  void **buffers;
  size_t nBuffers;
  size_t index;

  buffer_holder() : buffers(0), nBuffers(0), index(0) {

  }

  size_t next_index() {
    return ++index % nBuffers;
  }

  void *next() {
    return buffers[next_index()];
  }
};

static buffer_holder tx_buffers, rx_buffers;

static std::vector<int16_t> samples;
static std::vector<int16_t>::iterator samples_it, samples_end;

static std::vector<int32_t> rx_samples;
static int rx_stop_after = 102400;

typedef int32_t rx_sample_t;

static void *rx_callback(struct bladerf *dev,
                         struct bladerf_stream *stream,
                         struct bladerf_metadata *meta,
                         void *samples,
                         size_t num_samples,
                         void *user_data) {

  rx_sample_t *isamples = (rx_sample_t*)samples;

  std::copy(isamples, isamples + num_samples, std::back_inserter(rx_samples));
  //data_dump((uint16_t*)samples, num_samples);

  rx_stop_after -= num_samples;

  if (rx_stop_after <= 0) {
    data_dump((uint32_t*)&rx_samples[0], rx_samples.size());
    rx_samples.clear();
    return BLADERF_STREAM_SHUTDOWN;
  }

  return rx_buffers.next();
}

static void *tx_callback(struct bladerf *dev,
                         struct bladerf_stream *stream,
                         struct bladerf_metadata *meta,
                         void *samples,
                         size_t num_samples,
                         void *user_data) {

  static int samp_count;
  if (samples_it == samples_end) {
    std::cerr << "TX Complete: sent " << samp_count/2 << " samples\n";
    return BLADERF_STREAM_SHUTDOWN;
  }

  uint16_t *newbuf = (uint16_t*)tx_buffers.next();

  for (size_t i = 0; i < num_samples && samples_it != samples_end; i++, ++samples_it) {
    // newbuf[i] = 0x00A00000 + i; 
    if (samples_it != samples_end) {
      newbuf[i] = *samples_it;
      samp_count++;
    }
    else {
      newbuf[i] = 0xFFFF;
    }
  }

  return newbuf;
}

int main(int argc, char *argv[]) {
    struct bladerf *dev;
    int status;

    std::ifstream in_samples("./data_in.txt");
    std::ofstream in_samples_int("./data_in_int.txt");
    FILE *in_bin = fopen("./data_in.bin", "wb");


    while (!in_samples.eof()) {
      std::string line;
      std::getline(in_samples, line);

      std::stringstream ss(line);
      float i, q;
      ss >> i;
      ss >> q;

      // cout << "I: " << i << " Q:" <<  q << "\n";

      int16_t ii = i * (0xFFF >> 2), iq = q * (0xFFF >> 2);
      samples.push_back(ii);
      samples.push_back(iq);

      in_samples_int << std::setw(4) << std::hex << std::setfill('0') << ii;
      in_samples_int << " ";
      in_samples_int << std::setw(4) << std::hex << std::setfill('0') << iq << std::endl;

      fwrite((void*)&ii, sizeof(ii), 1, in_bin);
      fwrite((void*)&iq, sizeof(iq), 1, in_bin);

      assert(sizeof(ii) == 2);
      assert(sizeof(iq) == 2);
    }

    in_samples_int.close();

    std::cerr << "Read " << samples.size()/2 << " complex samples" << std::endl;

    samples_it = samples.begin();
    samples_end = samples.end();

    /* Skip the 6 first samples */
    for (size_t i = 0; i < 5*2; i++)
       ++samples_it;

    try {
        bladerf_log_set_verbosity(BLADERF_LOG_LEVEL_DEBUG);

        status = bladerf_open(&dev, "*");
        error_check(status);

        struct bladerf_stream *rx_stream, *tx_stream;

        rx_buffers.nBuffers = 16;
        status = bladerf_init_stream(&rx_stream, dev, rx_callback, &rx_buffers.buffers, 16, BLADERF_FORMAT_SC16_Q11, 10240, 8, NULL);
        error_check(status);

        tx_buffers.nBuffers = 16;
        status = bladerf_init_stream(&tx_stream, dev, tx_callback, &tx_buffers.buffers, 16, BLADERF_FORMAT_SC16_Q11, 10240, 8, NULL);
        error_check(status);

        if (argc > 1 && *argv[1]) {
          std::string mode = argv[1];

          bladerf_fpga_mux_t mux_mode = BLADERF_RX_MUX_NORMAL;

          if (mode == "fft") {
            mux_mode = BLADERF_RX_MUX_FFT;
          } else if (mode == "normal") {
            mux_mode = BLADERF_RX_MUX_NORMAL;
          } else if(mode == "counter") {
            mux_mode = BLADERF_RX_MUX_12BIT_COUNTER;
          } else if(mode == "counter32") {
            mux_mode = BLADERF_RX_MUX_32BIT_COUNTER;
          } else {
            mode = "normal";
          }

          status = bladerf_set_fpga_rx_mux(dev, mux_mode);
          error_check(status);

          cout << "Exiting after setting rx mux mode to " << mode << "\n";
          return 0;  
        }

        // Turn on FPGA loopback
        // status = bladerf_set_fpga_rx_mux(dev, BLADERF_RX_MUX_DIGITAL_LOOPBACK);
        status = bladerf_set_fpga_rx_mux(dev, BLADERF_RX_MUX_12BIT_COUNTER);
        error_check(status);

        // Turn on RF loopback
        status = bladerf_set_loopback(dev, BLADERF_LB_BB_TXVGA1_RXVGA2);
        error_check(status);

        bladerf_set_sample_rate(dev, BLADERF_MODULE_RX, 2000000, NULL);
        bladerf_set_sample_rate(dev, BLADERF_MODULE_TX, 2000000, NULL);

        bladerf_set_frequency(dev, BLADERF_MODULE_RX, 916000000);
        bladerf_set_frequency(dev, BLADERF_MODULE_TX, 915000000);

        // Enable RX & TX
        status = bladerf_enable_module(dev, BLADERF_MODULE_RX, true);
        error_check(status);

        status = bladerf_enable_module(dev, BLADERF_MODULE_TX, true);
        error_check(status);

        unsigned int timeout;
        bladerf_get_stream_timeout(dev, BLADERF_MODULE_RX, &timeout);
        std::cerr << "RX Timeout: " << timeout << std::endl;

        std::thread tx_thread([&]() {
            bladerf_stream(tx_stream, BLADERF_MODULE_TX);
        });

        std::thread rx_thread([&]() {
            bladerf_stream(rx_stream, BLADERF_MODULE_RX);
        });

        rx_thread.join();
        tx_thread.join();

        if (rx_samples.size()) {
          data_dump((uint32_t*)&rx_samples[0], rx_samples.size());
        }

        bladerf_deinit_stream(rx_stream);
        bladerf_deinit_stream(tx_stream);

        // Turn off FPGA loopback
        status = bladerf_set_fpga_rx_mux(dev, BLADERF_RX_MUX_NORMAL);
        error_check(status);

        status = bladerf_set_loopback(dev, BLADERF_LB_NONE);
        error_check(status);
    }
    catch (std::runtime_error &e) {
        cerr << "error: " << e.what() << "\n";
    }

    return 0;
}




