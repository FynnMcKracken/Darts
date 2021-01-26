#include "TimerOne.h"

/*
 * INPUT: Pins D0 to D9 (PIN0 to PIN9)
 * OUTPUT: Pins D10 to D12 and D18 to D23 (PIN10 to PIN12 and PIN18 to PIN23)
 */

const int inputPins[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
const int inputPinCount = sizeof(inputPins) / sizeof(inputPins[0]);

const int outputPins[] = {10, 11, 12, 18, 19, 20, 21, 22, 23};
const int outputPinCount = sizeof(outputPins) / sizeof(outputPins[0]);

const char* const hitCodes[90] = {
  "11x2", "14x2", "8x2", "16x2", "7x2", "19x2", "9x2", "12x2", "5x2", "20x2", 
  "11i", "14i", "8i", "16i", "7i", "19i", "9i", "12i", "5i", "20i", 
  "11x3", "14x3", "8x3", "16x3", "7x3", "19x3", "9x3", "12x3", "5x3", "20x3", 
  "11o", "14o", "8o", "16o", "7o", "19o", "9o", "12o", "5o", "20o", 
  "_40", "_41", "_42", "_43", "_44", "_45", "_46", "_47", "Bullseye", "Bullseyex2", 
  "10o", "6o", "15o", "2o", "17o", "3o", "13o", "4o", "18o", "1o", 
  "10x2", "6x2", "15x2", "2x2", "17x2", "3x2", "13x2", "4x2", "18x2", "1x2", 
  "10x3", "6x3", "15x3", "2x3", "17x3", "3x3", "13x3", "4x3", "18x3", "1x3", 
  "10i", "6i", "15i", "2i", "17i", "3i", "13i", "4i", "18i", "1i",
};

void setup() {
  Serial.begin(9600);

  pinMode(0, INPUT_PULLUP);
  pinMode(1, INPUT_PULLUP);
  pinMode(2, INPUT_PULLUP);
  pinMode(3, INPUT_PULLUP);
  pinMode(4, INPUT_PULLUP);
  pinMode(5, INPUT_PULLUP);
  pinMode(6, INPUT_PULLUP);
  pinMode(7, INPUT_PULLUP);
  pinMode(8, INPUT_PULLUP);
  pinMode(9, INPUT_PULLUP);

  pinMode(10, OUTPUT);
  digitalWrite(10, HIGH);
  
  pinMode(11, OUTPUT);
  digitalWrite(11, HIGH);

  pinMode(12, OUTPUT);
  digitalWrite(12, HIGH);
  
  pinMode(18, OUTPUT);
  digitalWrite(18, HIGH);

  pinMode(19, OUTPUT);
  digitalWrite(19, HIGH);
  
  pinMode(20, OUTPUT);
  digitalWrite(20, HIGH);
  
  pinMode(21, OUTPUT);
  digitalWrite(21, HIGH);

  pinMode(22, OUTPUT);
  digitalWrite(22, HIGH);
  
  pinMode(23, OUTPUT);
  digitalWrite(23, HIGH);

  Timer1.initialize(1000);
  Timer1.attachInterrupt(timer_isr);

}

void timer_isr() {
  static int outputPinCounter = 0;
  static bool hits[inputPinCount * outputPinCount];

  int outputPin = outputPins[outputPinCounter];
  digitalWrite(outputPin , LOW);

  for (int inputPinCounter = 0; inputPinCounter < inputPinCount; inputPinCounter++) {
    int inputPin = inputPins[inputPinCounter];
    int inputValue = digitalRead(inputPin);

    bool &wasHitInLastCycle = hits[outputPinCounter * inputPinCount + inputPinCounter];
    
    if (inputValue == LOW && !wasHitInLastCycle) {
      const char *hitCode = hitCodes[outputPinCounter * inputPinCount + inputPinCounter];
      
      Serial.print(hitCode);
      Serial.print("\n");
      
      wasHitInLastCycle = true;
    }

    if (inputValue == HIGH && wasHitInLastCycle) {
      wasHitInLastCycle = false;
    }
   
  }
  
  digitalWrite(outputPin, HIGH);
  outputPinCounter = (outputPinCounter + 1) % outputPinCount;
  
}

void loop() {}
