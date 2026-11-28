import 'package:flutter/material.dart';
import 'package:papeleria_app/models/user_session.dart';
import 'package:papeleria_app/services/api_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<dynamic> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final lista = await ApiService.getUsuarios();
      if (!mounted) return;
      setState(() => _usuarios = lista);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar usuarios: $e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _dialogoNuevoUsuario() async {
    final nombreCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String rolSeleccionado = 'Empleado';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario (login)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña inicial',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol y permisos',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Empleado',
                      child: Text('Empleado (Cajero)'),
                    ),
                    DropdownMenuItem(
                      value: 'Administrador',
                      child: Text('Administrador (Acceso total)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => rolSeleccionado = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty ||
                    userCtrl.text.trim().isEmpty ||
                    passCtrl.text.length < 4) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '⚠️ Completa todos los campos (contraseña mín. 4 caracteres)',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                try {
                  await ApiService.createUsuario(
                    nombreCompleto: nombreCtrl.text.trim(),
                    username: userCtrl.text.trim(),
                    password: passCtrl.text,
                    rol: rolSeleccionado,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('$e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Crear Usuario',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await _cargarUsuarios();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Usuario creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _dialogoResetPassword(Map<String, dynamic> u) async {
    final passCtrl = TextEditingController();
    final idUsuario = (u['idUsuario'] as num).toInt();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restablecer contraseña: ${u['username']}'),
        content: TextField(
          controller: passCtrl,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nueva contraseña',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passCtrl.text.trim().length < 4) return;
              try {
                await ApiService.resetUsuarioPassword(
                  idUsuario: idUsuario,
                  newPassword: passCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Guardar Nueva Contraseña'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔑 Contraseña actualizada y encriptada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _cambiarEstado(Map<String, dynamic> u, bool nuevoEstado) async {
    final idUsuario = (u['idUsuario'] as num).toInt();
    if (idUsuario == UserSession.current?.idUsuario) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No puedes desactivar tu propio usuario activo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await ApiService.toggleUsuarioEstado(
        idUsuario: idUsuario,
        activo: nuevoEstado,
      );
      await _cargarUsuarios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Usuarios y Roles',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onPressed: _dialogoNuevoUsuario,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Nuevo Usuario'),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: _cargarUsuarios,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Actualizar lista',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _usuarios.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = _usuarios[index] as Map<String, dynamic>;
                        final rolMap = u['rol'] as Map<String, dynamic>?;
                        final rolNombre = (rolMap?['nombre'] ?? 'Empleado')
                            .toString();
                        final esAdmin =
                            rolNombre.toLowerCase() == 'administrador';
                        final activo = u['activo'] != false;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: esAdmin
                                ? Colors.amber[800]
                                : Colors.blueAccent,
                            child: Icon(
                              esAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.badge,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${u['nombreCompleto']}  (@${u['username']})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: activo
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Text(
                            'Rol: $rolNombre  •  Estado: ${activo ? "Activo" : "Desactivado"}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Restablecer contraseña',
                                icon: const Icon(
                                  Icons.lock_reset,
                                  color: Colors.amber,
                                ),
                                onPressed: () => _dialogoResetPassword(u),
                              ),
                              Switch(
                                value: activo,
                                onChanged: (val) => _cambiarEstado(u, val),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
