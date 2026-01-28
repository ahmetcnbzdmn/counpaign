import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/swipe_back_detector.dart';
import '../../core/utils/ui_utils.dart';

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
  late TextEditingController _phoneNumberController;
  
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
    _phoneNumberController = TextEditingController(text: user?.phoneNumber);
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
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (image != null) {
      await _cropImage(image.path);
    }
  }

  Future<void> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğrafı Kırp',
          toolbarColor: const Color(0xFFEE2C2C),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          activeControlsWidgetColor: const Color(0xFFEE2C2C),
          dimmedLayerColor: Colors.black.withOpacity(0.8),
        ),
        IOSUiSettings(
          title: 'Fotoğrafı Kırp',
          doneButtonTitle: 'Bitti',
          cancelButtonTitle: 'İptal',
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetButtonHidden: true,
        ),
      ],
    );

    if (croppedFile != null) {
      final bytes = await xFileToBytes(croppedFile);
      setState(() {
        _newProfileImageBase64 = base64Encode(bytes);
        _profileImageBytes = bytes;
      });
    }
  }

  Future<Uint8List> xFileToBytes(CroppedFile file) async {
    return await file.readAsBytes();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await context.read<AuthProvider>().updateProfile(
          name: _nameController.text,
          surname: _surnameController.text,
          email: _emailController.text,
          phoneNumber: _phoneNumberController.text,
          profileImage: _newProfileImageBase64,
          gender: _selectedGender,
          birthDate: _selectedBirthDate,
        );
        if (mounted) {
           // Show Success Dialog
           showDialog(
             context: context,
             barrierDismissible: false,
             builder: (ctx) => Dialog(
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
               child: Padding(
                 padding: const EdgeInsets.all(24),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.green.withOpacity(0.1),
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                     ),
                     const SizedBox(height: 16),
                     Text(
                       "Profil Guncellendi!",
                       style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       "Değişikliklerin başarıyla kaydedildi.",
                       textAlign: TextAlign.center,
                       style: GoogleFonts.outfit(color: Colors.grey),
                     ),
                     const SizedBox(height: 24),
                     SizedBox(
                       width: double.infinity,
                       child: ElevatedButton(
                         onPressed: () {
                           Navigator.pop(ctx); // Close dialog
                           Navigator.pop(context); // Close screen
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFFEE2C2C),
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           padding: const EdgeInsets.symmetric(vertical: 16),
                         ),
                         child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold)),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
           );
        }
       } catch (e) {
         showCustomPopup(
           context,
           message: e.toString(),
           type: PopupType.error,
         );
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
      imageProvider = const AssetImage('assets/images/default_profile.png');
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Profili Düzenle", style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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

              // PHONE NUMBER FIELD (Above Email)
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Telefon numarası gerekli";
                  if (val.length != 10) return "10 hane olmalıdır (Başında 0 olmadan)";
                  if (!val.startsWith('5')) return "Numara 5 ile başlamalıdır";
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  _StartsWithFiveFormatter(), 
                ],
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Telefon Numarası",
                  counterText: "", // Hide character counter
                  labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  prefixIcon: Icon(Icons.phone_iphone_rounded, color: textColor.withOpacity(0.54)),
                  prefixText: "+90 ", // Visual hint
                  prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),

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
                    foregroundColor: Colors.white,
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
    
    return AbsorbPointer(
      child: TextFormField(
        enabled: false, // Visual feedback that it's disabled
        controller: TextEditingController(
          text: _selectedBirthDate == null ? "" : DateFormat('dd.MM.yyyy').format(_selectedBirthDate!)
        ),
        style: TextStyle(color: textColor.withOpacity(0.5)), // Dimmed text
        decoration: InputDecoration(
          labelText: "Doğum Tarihi",
          labelStyle: TextStyle(color: textColor.withOpacity(0.4)),
          prefixIcon: Icon(Icons.calendar_today, color: textColor.withOpacity(0.3)), // Dimmed icon
          filled: true,
          fillColor: cardColor.withOpacity(0.5), // Dimmed background
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          suffixIcon: Icon(Icons.lock_outline, color: textColor.withOpacity(0.3)), // Lock icon instead of arrow
        ),
      ),
    );
  }
}

// Helper Class for strict '5' start
class _StartsWithFiveFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // If the first character is NOT '5', prevent the update (return old value)
    if (!newValue.text.startsWith('5')) {
      // If they are deleting the first character, allow it (becomes empty)
      if (oldValue.text.isNotEmpty && oldValue.text.length > newValue.text.length) {
         // Allow deletion (which might leave empty)
         return newValue;
      }
      // Otherwise (typing), block non-5 start
      return oldValue; 
    }
    return newValue;
  }
}
