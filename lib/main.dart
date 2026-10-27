import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'course.dart';
import 'weather.dart';

void main() {
  runApp(const MyWeekApp());
}

IconData iconFor(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code <= 3) return Icons.cloud;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 95) return Icons.thunderstorm;
  if (code >= 51) return Icons.water_drop;
  return Icons.help_outline;
}

class MyWeekApp extends StatelessWidget {
  const MyWeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const WeekScreen(),
    );
  }
}

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  List<Course> courses = sampleCourses();

  Weather? weather;
  bool weatherLoading = true;
  String? weatherError;

  @override
  void initState() {
    super.initState();
    loadCourses();
    loadWeather();
  }

  // ---------- SAVING ----------

  Future<void> saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final list = courses.map((c) => c.toJson()).toList();
    await prefs.setString('courses', jsonEncode(list));
  }

  Future<void> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('courses');
    if (saved != null) {
      final list = jsonDecode(saved) as List;
      setState(() {
        courses = list
            .map((x) => Course.fromJson(x as Map<String, dynamic>))
            .toList();
      });
    }
  }
  Future<void> loadWeather() async {
    try {
      final result = await fetchWeather();
      setState(() {
        weather = result;
        weatherLoading = false;
        weatherError = null;
      });
    } catch (e) {
      setState(() {
        weatherLoading = false;
        weatherError = 'Could not load the weather. Check your internet connection.';
      });
    }
  }

  void retryWeather() {
    setState(() {
      weatherLoading = true;
      weatherError = null;
    });
    loadWeather();
  }

  Widget weatherHeader() {
    if (weatherLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (weatherError != null) {
      return Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.wifi_off),
              const SizedBox(width: 12),
              Expanded(child: Text(weatherError!)),
              TextButton(onPressed: retryWeather, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: Icon(iconFor(weather!.code), size: 40, color: Colors.blue),
        title: Text('Kigali today: ${weather!.temperature.round()}°C'),
        subtitle: Text(describe(weather!.code)),
      ),
    );
  }

  // ---------- ADD / EDIT ----------

  Future<void> openForm({Course? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final start = TextEditingController(text: existing?.start ?? '');
    final end = TextEditingController(text: existing?.end ?? '');
    final room = TextEditingController(text: existing?.room ?? '');
    String day = existing?.day ?? days.first;

    final result = await showDialog<Course>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add course' : 'Edit course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Course'),
                ),
                DropdownButton<String>(
                  value: day,
                  isExpanded: true,
                  items: [
                    for (final d in days)
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      day = value!;
                    });
                  },
                ),
                TextField(
                  controller: start,
                  decoration: const InputDecoration(labelText: 'Start (e.g. 08:30)'),
                ),
                TextField(
                  controller: end,
                  decoration: const InputDecoration(labelText: 'End (e.g. 12:30)'),
                ),
                TextField(
                  controller: room,
                  decoration: const InputDecoration(labelText: 'Room'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty) return;
                Navigator.pop(
                  context,
                  Course(
                    title.text.trim(),
                    day,
                    start.text.trim(),
                    end.text.trim(),
                    room.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      if (existing == null) {
        courses.add(result);
      } else {
        final i = courses.indexOf(existing);
        courses[i] = result;
      }
    });
    saveCourses();
  }

  // ---------- DELETE + UNDO ----------

  void deleteCourse(Course course) {
    final index = courses.indexOf(course);
    setState(() {
      courses.removeAt(index);
    });
    saveCourses();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${course.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              final position = index > courses.length ? courses.length : index;
              courses.insert(position, course);
            });
            saveCourses();
          },
        ),
      ),
    );
  }

  // ---------- SCREEN ----------

  @override
  Widget build(BuildContext context) {
    final sorted = [...courses]
      ..sort((a, b) {
        final byDay = days.indexOf(a.day).compareTo(days.indexOf(b.day));
        return byDay != 0 ? byDay : a.start.compareTo(b.start);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('My Week')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openForm(),
        child: const Icon(Icons.add),
      ),
      body: sorted.isEmpty
          ? const Center(child: Text('No courses yet. Tap + to add one.'))
          : ListView(
        children: [
          weatherHeader(),
          for (final d in days)
            if (sorted.any((c) => c.day == d)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  d,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final c in sorted.where((c) => c.day == d))
                ListTile(
                  title: Text(c.title),
                  subtitle: Text('${c.start} - ${c.end}  ·  ${c.room}'),
                  onTap: () => openForm(existing: c),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => deleteCourse(c),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}