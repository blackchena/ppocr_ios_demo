#pragma once

#include "common.h"
#include <opencv2/opencv.hpp>

cv::Mat resize_img(const cv::Mat &img, int height, int width);

void neon_mean_scale(const float *din, float *dout, int size,
                     const std::vector<float> &mean,
                     const std::vector<float> &scale);
