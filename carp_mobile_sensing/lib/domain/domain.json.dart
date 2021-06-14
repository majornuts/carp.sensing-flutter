part of domain;

bool _fromJsonFunctionsRegistrered = false;

// Register all the fromJson functions for the domain classes.
void _registerFromJsonFunctions() {
  if (_fromJsonFunctionsRegistrered) return;
  _fromJsonFunctionsRegistrered = true;

  // Protocol classes
  // FromJsonFactory().register(CAMSStudyProtocol());
  FromJsonFactory().register(StudyProtocolReponsible());
  FromJsonFactory().register(DataEndPoint(type: ''));
  FromJsonFactory().register(FileDataEndPoint(dataFormat: ''));
  FromJsonFactory().register(StudyProtocolDescription());

  // Task classes
  FromJsonFactory().register(AutomaticTask());
  FromJsonFactory().register(AppTask(type: 'ignored'));

  // Trigger classes
  FromJsonFactory().register(ImmediateTrigger());
  FromJsonFactory().register(DelayedTrigger());
  FromJsonFactory().register(PeriodicTrigger(period: Duration()));
  FromJsonFactory().register(DateTimeTrigger(schedule: DateTime.now()));
  FromJsonFactory().register(Time());
  FromJsonFactory().register(
      RecurrentScheduledTrigger(type: RecurrentType.daily, time: Time()));
  FromJsonFactory().register(SamplingEventTrigger(measureType: 'ignored'));
  FromJsonFactory().register(ConditionalEvent({}));
  FromJsonFactory().register(ConditionalSamplingEventTrigger(
      measureType: 'ignored', resumeCondition: (DataPoint dataPoint) => true));
  FromJsonFactory().register(
      RandomRecurrentTrigger(endTime: Time.now(), startTime: Time.now()));

  // Measure classes
  FromJsonFactory().register(CAMSMeasure(type: 'ignored'));
  FromJsonFactory().register(
      PeriodicMeasure(type: 'ignored', frequency: Duration(seconds: 1)));
  FromJsonFactory().register(MarkedMeasure(type: 'ignored'));
}

class DomainJsonFactory {
  DomainJsonFactory() {
    _registerFromJsonFunctions();
  }
}

var tmp = DomainJsonFactory();
