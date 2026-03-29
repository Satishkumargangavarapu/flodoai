import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../api_config.dart';

class TaskProvider with ChangeNotifier {
  List<TaskItem> _tasks = [];
  List<TaskItem> _filteredTasks = [];
  
  bool _isLoading = false;
  
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'To-Do', 'In Progress', 'Done'

  final _searchSubject = PublishSubject<String>();

  TaskProvider() {
    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen((query) {
      _searchQuery = query;
      _applyFilters();
    });
    fetchTasks();
  }

  List<TaskItem> get tasks => _filteredTasks;
  List<TaskItem> get allTasks => _tasks; // Used for "Blocked By" dropdown
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<Map<String, String>> _getHeaders({bool isJson = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      if (isJson) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/tasks'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tasks = data.map((json) => TaskItem.fromMap(json)).toList();
        _applyFilters();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredTasks = _tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'All' || task.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _searchSubject.add(query);
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }
  
  String get statusFilter => _statusFilter;

  // Simulate 2-second delay for Create and Update
  Future<void> addTask(TaskItem task) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      final headers = await _getHeaders(isJson: true);
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode(task.toMap()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final createdTask = TaskItem.fromMap(jsonDecode(response.body));
        _tasks.add(createdTask);
        _applyFilters();
      } else {
        throw Exception('Failed to create task');
      }
    } catch (e) {
      debugPrint("Error adding task: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(TaskItem task) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      final headers = await _getHeaders(isJson: true);
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/${task.id}'),
        headers: headers,
        body: jsonEncode(task.toMap()),
      );
      if (response.statusCode == 200) {
        final updatedTask = TaskItem.fromMap(jsonDecode(response.body));
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
          _applyFilters();
        }
      } else {
        throw Exception('Failed to update task');
      }
    } catch (e) {
      debugPrint("Error updating task: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(int id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'), headers: headers);
      if (response.statusCode == 200) {
        _tasks.removeWhere((t) => t.id == id);
        // If deleted task was blocking others, might want to handle it. Keeping UI simple.
        _applyFilters();
      } else {
        throw Exception('Failed to delete task');
      }
    } catch (e) {
      debugPrint("Error deleting task: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isTaskBlocked(TaskItem task) {
    if (task.blockedBy == null) return false;
    TaskItem? blockingTask;
    for (var t in _tasks) {
      if (t.id == task.blockedBy) {
        blockingTask = t;
        break;
      }
    }
    if (blockingTask != null && blockingTask.status != 'Done') {
      return true;
    }
    return false;
  }
}
