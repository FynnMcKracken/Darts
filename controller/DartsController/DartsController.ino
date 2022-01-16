#include "TimerOne.h"
#include "Dartboard.h"

void setup() {
  Serial.begin(9600);

  for (int i = 0; i < outputPinCount; i++) {
    pinMode(outputPins[i], OUTPUT);
    digitalWrite(outputPins[i], HIGH);
  }

  for (int i = 0; i < inputPinCount; i++) {
    pinMode(inputPins[i], INPUT_PULLUP);
  }

  Timer1.initialize(128);
  Timer1.attachInterrupt(timer_isr);
}

void timer_isr() {
  static int outputPinCounter = 0;
  static bool *hits = malloc(hitCodeCount * sizeof(bool));
  static int timeout = 0;

  if (timeout == 0) {
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
        timeout = 150;
      }
  
      if (inputValue == HIGH && wasHitInLastCycle) {
        wasHitInLastCycle = false;
      }
    }
    
    digitalWrite(outputPin, HIGH);
    outputPinCounter = (outputPinCounter + 1) % outputPinCount;
  } else {
    timeout = timeout - 1;
  }
}

void loop() {}
