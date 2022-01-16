#ifdef DARTBOARD_Aspiria_ANS_16_013

#include "Dartboard.h"

const int outputPins[] = {18, 19, 20, 21, 22, 23, 14, 15};
const int outputPinCount = sizeof(outputPins) / sizeof(outputPins[0]);

const int inputPins[] = {0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
const int inputPinCount = sizeof(inputPins) / sizeof(inputPins[0]);

const int hitCodeCount = outputPinCount * inputPinCount;
const char* const hitCodes[hitCodeCount] = {
  "19x3", "16i", "17o", "2o", "15o", "15x2", "12x3", "10x2", "10o", "6o", "1i", "4x3",
  "19i", "3i", "17i", "2i", "15i", "_18", "12i", "_20", "10x3", "6x3", "13x3", "18i",
  "7i", "3x3", "17x3", "2x3", "15x3", "Bullseye", "9i", "Bullseyex2", "10i", "6i", "13i", "4i",
  "7x3", "3o", "8i", "11i", "14i", "2x2", "9x3", "6x2", "5i", "20i", "13o", "18x3",
  "19o", "16x3", "8x3", "11x3", "14x3", "17x2", "12o", "13x2", "5x3", "20x3", "1x3", "4o",
  "7o", "16o", "8o", "11o", "14o", "3x2", "9o", "4x2", "5o", "20o", "1o", "18o",
  "7x2", "16x2", "8x2", "11x2", "14x2", "19x2", "9x2", "12x2", "5x2", "20x2", "1x2", "18x2",
  "_85", "_86", "_87", "_88", "_89", "_90", "_91", "_92", "_93", "_94", "_95", "_96"
};

#endif
