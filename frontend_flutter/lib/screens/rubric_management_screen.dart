import 'package:flutter/material.dart';
import '../models/rubric_model.dart';
import '../services/api_service.dart';
import '../models/rubric_model.dart';
import '../models/criterion_model.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class RubricManagementScreen extends StatefulWidget {
  final String teacherId;
  const RubricManagementScreen({super.key, required this.teacherId});

  @override
  State<RubricManagementScreen> createState() => _RubricManagementScreenState();
}

class _RubricManagementScreenState extends State<RubricManagementScreen> {
  final ApiService _apiService = ApiService();
  final _nameController = TextEditingController();
  
  List<Rubric> _rubrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRubrics();
  }

  Future<void> _loadRubrics() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getRubrics(creatorId: widget.teacherId);
    setState(() {
      _rubrics = data;
      _isLoading = false;
    });
  }

  void _addItem(List<Map<String, dynamic>> items, StateSetter setModalState) {
    setModalState(() {
      items.add({
        'criteria': 'Criterio ${items.length + 1}',
        'maxPoints': 10,
        'description': '',
      });
    });
  }

  void _loadTemplate(List<Map<String, dynamic>> items, StateSetter setModalState) {
    setModalState(() {
      items.clear();
      items.addAll([
        {'criteria': 'Innovación', 'maxPoints': 25, 'description': 'Originalidad de la idea.'},
        {'criteria': 'Factibilidad', 'maxPoints': 25, 'description': 'Viabilidad técnica.'},
        {'criteria': 'Presentación', 'maxPoints': 25, 'description': 'Calidad de la exposición.'},
        {'criteria': 'Impacto', 'maxPoints': 25, 'description': 'Beneficio esperado.'},
      ]);
    });
  }

  void _showCreateDialog([Rubric? existingRubric]) {
    List<Map<String, dynamic>> items = existingRubric != null
        ? existingRubric.items.map((c) => {'criteria': c.criteria, 'description': c.description, 'maxPoints': c.maxPoints}).toList()
        : [];
    _nameController.text = existingRubric?.name ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make background transparent for blur
      elevation: 0,
      builder: (context) => StatefulBuilder(
        builder: (sContext, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark.withOpacity(0.85) : Colors.white.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(existingRubric != null ? 'Editar Lista/Rúbrica' : 'Nueva Lista/Rúbrica', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la lista',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Criterios de Evaluación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          onPressed: () => _loadTemplate(items, setModalState),
                          icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                          label: const Text('Usar Plantilla'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    items.isEmpty 
                      ? Center(child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text('Añade criterios pulsando el botón de abajo', style: TextStyle(color: Colors.grey[600])),
                        ))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (lContext, index) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        decoration: const InputDecoration(hintText: 'Nombre del criterio', isDense: true),
                                        onChanged: (v) => items[index]['criteria'] = v,
                                        controller: TextEditingController(text: items[index]['criteria'])..selection = TextSelection.fromPosition(TextPosition(offset: (items[index]['criteria'] as String).length)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                        decoration: const InputDecoration(hintText: 'Pts', isDense: true),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => items[index]['maxPoints'] = int.tryParse(v) ?? 0,
                                        controller: TextEditingController(text: items[index]['maxPoints'].toString()),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => setModalState(() => items.removeAt(index)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: const InputDecoration(hintText: 'Descripción del criterio (ej. Detalles, reglas)', isDense: true),
                                  onChanged: (v) => items[index]['description'] = v,
                                  controller: TextEditingController(text: items[index]['description'])..selection = TextSelection.fromPosition(TextPosition(offset: (items[index]['description']?.toString().length ?? 0))),
                                ),
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _addItem(items, setModalState),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir Criterio'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ponle un nombre a la rúbrica')));
                          return;
                        }
                        for (var item in items) {
                          if ((item['criteria'] as String).isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todos los criterios deben tener nombre')));
                            return;
                          }
                        }
                        
                        final payload = {
                          'name': _nameController.text,
                          'items': items,
                          'creatorId': widget.teacherId,
                          'isGlobal': false,
                        };

                        bool success;
                        if (existingRubric != null && existingRubric.id != null) {
                          success = await _apiService.updateRubric(existingRubric.id!, payload);
                        } else {
                          success = await _apiService.createRubric(payload);
                        }
                        
                        if (success) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          _loadRubrics();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existingRubric != null ? 'Rúbrica actualizada con éxito' : 'Rúbrica guardada con éxito')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar la rúbrica: revisa la conexión.')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar Rúbrica Final'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Listas de Cotejo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        label: const Text('Crear Nueva'),
        icon: const Icon(Icons.add_task),
        backgroundColor: AppColors.primaryYellow,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _rubrics.length,
            itemBuilder: (context, index) {
              final rubric = _rubrics[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(rubric.name ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${rubric.items.length} criterios'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCreateDialog(rubric),
                ),
              );
            },
          ),
    );
  }
}
