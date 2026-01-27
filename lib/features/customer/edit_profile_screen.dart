import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _newProfileImageBase64;
  Uint8List? _profileImageBytes;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name);
    _surnameController = TextEditingController(text: user?.surname);
    _emailController = TextEditingController(text: user?.email);
    _selectedGender = user?.gender;
    _selectedBirthDate = user?.birthDate;
    
    if (user?.profileImage != null) {
      try {
        _profileImageBytes = base64Decode(user!.profileImage!);
      } catch (e) {
        print("Error decoding initial profile image: $e");
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _newProfileImageBase64 = base64Encode(bytes);
        _profileImageBytes = bytes;
      });
    }
  }

  Future<void> _pickDate() async {
    final initialDate = _selectedBirthDate ?? DateTime(2000);
    DateTime tempPickedDate = initialDate;
    
    // iOS Style Date Picker
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            // Toolbar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Bitti', style: TextStyle(color: Color(0xFFEE2C2C), fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        // Normalize to noon to avoid timezone issues
                        _selectedBirthDate = DateTime(
                          tempPickedDate.year,
                          tempPickedDate.month,
                          tempPickedDate.day,
                          12,
                        );
                      });
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 240,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: DateTime(1900),
                maximumDate: DateTime.now(),
                use24hFormat: true,
                onDateTimeChanged: (val) {
                  tempPickedDate = val;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await context.read<AuthProvider>().updateProfile(
          name: _nameController.text,
          surname: _surnameController.text,
          email: _emailController.text,
          profileImage: _newProfileImageBase64,
          gender: _selectedGender,
          birthDate: _selectedBirthDate,
        );
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil güncellendi!")));
           Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = theme.cardColor;
    const primaryBrand = Color(0xFFEE2C2C);

    ImageProvider? imageProvider;
    if (_profileImageBytes != null) {
      imageProvider = MemoryImage(_profileImageBytes!);
    } else {
      imageProvider = const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200');
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Profili Düzenle", style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryBrand, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundImage: imageProvider,
                        backgroundColor: Colors.grey[800],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: primaryBrand,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _buildTextField(controller: _nameController, label: "Ad", icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(controller: _surnameController, label: "Soyad", icon: Icons.person_outline),
              const SizedBox(height: 16),
              
              // Gender Dropdown
              _buildDropdownField(),
              
              const SizedBox(height: 16),
              
              // Birth Date Picker
              _buildDatePickerField(),
              
              const SizedBox(height: 16),
              _buildTextField(controller: _emailController, label: "E-posta", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrand,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: context.watch<AuthProvider>().isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text("Değişiklikleri Kaydet"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      validator: (val) => val == null || val.isEmpty ? "Bu alan boş bırakılamaz" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: textColor.withOpacity(0.54)),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEE2C2C))),
      ),
    );
  }

  Widget _buildDropdownField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: cardColor,
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        style: TextStyle(color: textColor),
        borderRadius: BorderRadius.circular(20), 
        decoration: InputDecoration(
          labelText: "Cinsiyet",
          labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
          prefixIcon: Icon(Icons.wc, color: textColor.withOpacity(0.54)),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        items: const [
          DropdownMenuItem(value: "male", child: Text("Erkek")),
          DropdownMenuItem(value: "female", child: Text("Kadın")),
          DropdownMenuItem(value: "other", child: Text("Diğer")),
          DropdownMenuItem(value: "", child: Text("Belirtmek İstemiyorum")),
        ],
        onChanged: (val) {
          setState(() {
            _selectedGender = val;
          });
        },
      ),
    );
  }

  Widget _buildDatePickerField() {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
            text: _selectedBirthDate == null ? "" : DateFormat('dd.MM.yyyy').format(_selectedBirthDate!)
          ),
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: "Doğum Tarihi",
            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
            prefixIcon: Icon(Icons.calendar_today, color: textColor.withOpacity(0.54)),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            suffixIcon: Icon(Icons.arrow_drop_down, color: textColor.withOpacity(0.54)),
          ),
        ),
      ),
    );
  }
}
