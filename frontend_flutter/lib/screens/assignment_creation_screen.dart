import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/assignment_model.dart';
import '../models/rubric_model.dart';
import '../models/classroom_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../models/notification_model.dart';

class AssignmentCreationScreen extends StatefulWidget {
  final String teacherId;
  final String? initialClassroomId;
  final Assignment? assignment;
  const AssignmentCreationScreen({super.key, required this.teacherId, this.initialClassroomId, this.assignment});

  @override
  State<AssignmentCreationScreen> createState() => _AssignmentCreationScreenState();
}

class _AssignmentCreationScreenState extends State<AssignmentCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  List<Rubric> _rubrics = [];
  String? _selectedRubricId;
  bool _isLoadingRubrics = true;
  bool _isSaving = false;
  DateTime? _selectedDate;
  List<Classroom> _classes = [];
  String? _selectedClassId;
  bool _isLoadingClasses = true;

  List<JurorAssignment> _jurors = [];
  final _jurorEmailController = TextEditingController();
  final _jurorWeightController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    if (widget.assignment != null) {
      _titleController.text = widget.assignment!.title;
      _descriptionController.text = widget.assignment!.description;
      _selectedClassId = widget.assignment!.classroomId;
      _selectedRubricId = widget.assignment!.rubricId;
      _selectedDate = widget.assignment!.dueDate;
      _jurors = widget.assignment!.jurors ?? [];
    } else {
      _selectedClassId = widget.initialClassroomId;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchRubrics(),
      _fetchClasses(),
    ]);
  }

  Future<void> _fetchClasses() async {
    try {
      final classes = await _apiService.getClassrooms(teacherId: widget.teacherId);
      setState(() {
        _classes = classes;
        _isLoadingClasses = false;
      });
    } catch (e) {
      debugPrint('Error fetching classes: $e');
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _fetchRubrics() async {
    try {
      final rubrics = await _apiService.getRubrics(creatorId: widget.teacherId);
      setState(() {
        _rubrics = rubrics;
        _isLoadingRubrics = false;
      });
    } catch (e) {
      debugPrint('Error fetching rubrics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar rúbricas: $e')),
        );
      }
      setState(() => _isLoadingRubrics = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now().copyWith(hour: 23, minute: 59)),
      );
      
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[DateTime.now().microsecond % chars.length]).join();
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final assignment = Assignment(
        id: widget.assignment?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        teacherId: widget.teacherId,
        rubricId: _selectedRubricId,
        dueDate: _selectedDate,
        accessCode: null,
        classroomId: _selectedClassId,
        jurors: _jurors.isNotEmpty ? _jurors : null,
      );

      final success = widget.assignment != null 
        ? await _apiService.updateAssignment(assignment)
        : await _apiService.createAssignment(assignment);

      if (mounted) {
        if (success) {
          // Notify students if it's a new assignment
          if (widget.assignment == null && _selectedClassId != null) {
            try {
              final members = await _apiService.getClassMembers(_selectedClassId!);
              for (var m in members) {
                if (m.status.toLowerCase() == 'approved') {
                  await _apiService.createNotification(AppNotification(
                    userId: m.studentId,
                    title: '🌟 Nueva Tarea',
                    message: 'Se ha asignado una nueva tarea: ${_titleController.text}',
                    createdAt: DateTime.now(),
                  ));
                }
              }
            } catch (_) {}
          }

          if (widget.assignment != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tarea actualizada')),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Tarea publicada con éxito!')),
            );
            Navigator.pop(context, true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al ${widget.assignment != null ? 'actualizar' : 'crear'} la convocatoria')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.assignment != null ? 'Editar Tarea' : 'Nueva Tarea')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crea una nueva tarea para que tus alumnos puedan subir sus proyectos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título (ej: Tarea 1: Introducción)',
                  prefixIcon: Icon(Icons.campaign),
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Instrucciones',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 24),
              _isLoadingRubrics 
                ? const LinearProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRubricId,
                        decoration: InputDecoration(
                          labelText: 'Seleccionar Rúbrica de Evaluación',
                          prefixIcon: const Icon(Icons.rule),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _fetchRubrics,
                          ),
                        ),
                        items: _rubrics.map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name ?? 'Rúbrica sin nombre'),
                        )).toList(),
                        onChanged: _rubrics.isEmpty ? null : (val) => setState(() => _selectedRubricId = val),
                        validator: (val) => val == null ? 'Selecciona una rúbrica' : null,
                      ),
                      if (_rubrics.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Aviso: Debes crear al menos una rúbrica antes de publicar una tarea.',
                            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
              const SizedBox(height: 16),
              _isLoadingClasses
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: InputDecoration(
                      labelText: 'Vincular a Clase',
                      prefixIcon: const Icon(Icons.class_outlined),
                      helperText: widget.initialClassroomId != null ? 'Clase seleccionada automáticamente' : null,
                    ),
                    items: _classes.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: widget.initialClassroomId != null ? null : (val) => setState(() => _selectedClassId = val),
                    validator: (val) => val == null ? 'Vincular a una clase es obligatorio' : null,
                  ),
              const SizedBox(height: 16),
              const Text('Jurados Asignados (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _jurorEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo del Jurado',
                        hintText: 'ej: profesor@escuela.edu',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _jurorWeightController,
                      decoration: const InputDecoration(
                        labelText: 'Peso (%)',
                        hintText: 'Ej: 50',
                        prefixIcon: Icon(Icons.percent, size: 20),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: IconButton(
                      onPressed: () {
                        final email = _jurorEmailController.text.trim();
                        final weightText = _jurorWeightController.text.trim();
                        if (email.isEmpty || weightText.isEmpty) return;
                        if (!email.contains('@')) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correo inválido')));
                           return;
                        }
                        final weight = int.tryParse(weightText) ?? 0;
                        if (weight <= 0 || weight > 100) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Porcentaje inválido')));
                           return;
                        }
                        setState(() {
                          _jurors.add(JurorAssignment(email: email, weightPercentage: weight));
                          _jurorEmailController.clear();
                          _jurorWeightController.text = '100'; // Reset
                        });
                      },
                      icon: const Icon(Icons.add_circle, size: 36, color: AppColors.primaryYellow),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_jurors.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _jurors.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final j = _jurors[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.backgroundWhite,
                          child: Icon(Icons.person_outline, color: AppColors.primaryYellow),
                        ),
                        title: Text(j.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Peso de calificación general: ${j.weightPercentage}%'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => _jurors.removeAt(index)),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              ListTile(
                title: Text(_selectedDate == null 
                  ? 'Fecha y Hora de Entrega (Opcional)' 
                  : 'Entrega: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} ${_selectedDate!.hour.toString().padLeft(2, '0')}:${_selectedDate!.minute.toString().padLeft(2, '0')}'),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAssignment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primaryYellow,
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.assignment != null ? 'Guardar Cambios' : 'Publicar Tarea', style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
