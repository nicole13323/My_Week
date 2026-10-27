class Course {
  Course(this.title, this.day, this.start, this.end, this.room);

  final String title;
  final String day;
  final String start;
  final String end;
  final String room;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'day': day,
      'start': start,
      'end': end,
      'room': room,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      json['title'] as String,
      json['day'] as String,
      json['start'] as String,
      json['end'] as String,
      json['room'] as String,
    );
  }
}

const days = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

List<Course> sampleCourses() {
  return [
    Course('Innovation Center', 'Sunday', '08:30', '12:30', 'G310'),
    Course('INSY 8321 Data Structures and Algorithms', 'Sunday', '14:00', '18:00', 'G204'),
    Course('ENGL 8221 English Proficiency Certificate', 'Monday', '08:30', '11:30', 'GB5'),
    Course('Innovation Center', 'Monday', '18:00', '21:00', 'G310'),
    Course('INSY 8322 Web Technology and Internet', 'Tuesday', '08:00', '12:00', 'G204'),
    Course('INSY 8411 Dot Net', 'Tuesday', '14:00', '18:00', 'G308'),
    Course('ITS0017 ICDL', 'Wednesday', '11:30', '15:30', 'G209'),
    Course('Innovation Center', 'Wednesday', '18:00', '21:00', 'G310'),
    Course('SENG 8315 Software Project Management', 'Thursday', '18:00', '21:00', 'G205'),
    Course('MATH 8214 Multivariable Calculus and ODE', 'Friday', '12:00', '16:00', 'G206'),
  ];
}