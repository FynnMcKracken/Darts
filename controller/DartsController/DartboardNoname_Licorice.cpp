#ifdef DARTBOARD_Noname_Licorice

#include "Dartboard.h"

const int outputPins[] = {10, 11, 12, 18, 19, 20, 21, 22, 23};
const int outputPinCount = sizeof(outputPins) / sizeof(outputPins[0]);

const int inputPins[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
const int inputPinCount = sizeof(inputPins) / sizeof(inputPins[0]);

const int hitCodeCount = outputPinCount * inputPinCount;
const char* const hitCodes[hitCodeCount] = {
  "8i", "11i", "16i", "7i", "19i", "14i", "3i", "9i", "12i", "5i",
  "8x3", "11x3", "16x3", "7x3", "19x3", "14x3", "3x3", "9x3", "12x3", "5x3",
  "8x2", "11x2", "16x2", "7x2", "19x2", "14x2", "3x2", "9x2", "12x2", "5x2",
  "8o", "11o", "16o", "7o", "19o", "14o", "3o", "9o", "12o", "5o",
  "_40", "_41", "_42", "_43", "_44", "_45", "_46", "_47", "Bullseye", "Bullseyex2",
  "6o", "13o", "10o", "15o", "2o", "4o", "17o", "18o", "1o", "20o",
  "6x2", "13x2", "10x2", "15x2", "2x2", "4x2", "17x2", "18x2", "1x2", "20x2",
  "6x3", "13x3", "10x3", "15x3", "2x3", "4x3", "17x3", "18x3", "1x3", "20x3",
  "6i", "13i", "10i", "15i", "2i", "4i", "17i", "18i", "1i", "20i",
};

#endif
