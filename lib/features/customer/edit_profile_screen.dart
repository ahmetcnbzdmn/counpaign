import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/providers/language_provider.dart';

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
        debugPrint("Error decoding initial profile image: $e");
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
    final lang = context.read<LanguageProvider>();
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: lang.translate('crop_image'),
          toolbarColor: const Color(0xFF76410B),
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          activeControlsWidgetColor: const Color(0xFFF9C06A),
          dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
          cropGridColor: const Color(0xFFF9C06A),
          cropFrameColor: const Color(0xFFF9C06A),
        ),
        IOSUiSettings(
          title: lang.translate('crop_image'),
          doneButtonTitle: lang.translate('done'),
          cancelButtonTitle: lang.translate('cancel'),
          cropStyle: CropStyle.circle,
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
                         color: const Color(0xFFF9C06A).withValues(alpha: 0.1),
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.check_circle_rounded, color: Color(0xFFF9C06A), size: 48),
                     ),
                     const SizedBox(height: 16),
                     Text(
                       context.read<LanguageProvider>().translate('profile_updated'),
                       style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       context.read<LanguageProvider>().translate('changes_saved_msg'),
                       textAlign: TextAlign.center,
                       style: GoogleFonts.outfit(color: Colors.grey),
                     ),
                     const SizedBox(height: 24),
                     SizedBox(
                       width: double.infinity,
                       child: Container(
                         decoration: BoxDecoration(
                           color: const Color(0xFFF9C06A),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: ElevatedButton(
                           onPressed: () {
                             Navigator.pop(ctx); // Close dialog
                             Navigator.pop(context); // Close screen
                           },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.transparent,
                             shadowColor: Colors.transparent,
                             foregroundColor: Colors.white,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             padding: const EdgeInsets.symmetric(vertical: 16),
                           ),
                           child: Text(context.read<LanguageProvider>().translate('ok'), style: const TextStyle(fontWeight: FontWeight.bold)),
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
           );
        }
       } catch (e) {
         if (mounted) {
           showCustomPopup(
             context,
             message: e.toString(),
             type: PopupType.error,
           );
         }
       }
     }
   }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF131313);
    const cardColor = Colors.white;
    const primaryBrand = Color(0xFF76410B);
    final lang = context.watch<LanguageProvider>();

    ImageProvider? imageProvider;
    if (_profileImageBytes != null) {
      imageProvider = MemoryImage(_profileImageBytes!);
    } else {
      imageProvider = const AssetImage('assets/images/default_profile.png');
    }

    return Container(
      color: const Color(0xFFF6F0EB), // Top notch color match
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(lang.translate('edit_profile'), style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFF6F0EB),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
          ),
      body: Container(
        height: double.infinity,
        color: const Color(0xFFEBEBEB), // Body background
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
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
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9C06A), // Main yellow theme color
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, size: 40, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _buildTextField(controller: _nameController, label: lang.translate('name'), icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(controller: _surnameController, label: lang.translate('surname'), icon: Icons.person_outline),
              const SizedBox(height: 16),
              
              // Gender Dropdown
              _buildDropdownField(lang),
              
              const SizedBox(height: 16),
              
              // Birth Date Picker
              _buildDatePickerField(lang),
              
              const SizedBox(height: 16),

              // PHONE NUMBER FIELD
              TextFormField(
                controller: _phoneNumberController,
                readOnly: context.read<AuthProvider>().currentUser?.isVerified ?? false,
                style: TextStyle(
                  color: (context.read<AuthProvider>().currentUser?.isVerified ?? false) 
                      ? textColor.withValues(alpha: 0.7) 
                      : textColor, 
                  fontWeight: FontWeight.bold
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (val) {
                  if (val == null || val.isEmpty) return lang.translate('fill_all_fields');
                  if (val.length != 10) return lang.translate('phone_length_error');
                  if (!val.startsWith('5')) return lang.translate('phone_start_5');
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  _StartsWithFiveFormatter(), 
                ],
                decoration: InputDecoration(
                  labelText: lang.translate('phone_number'),
                  counterText: "",
                  labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.phone_iphone_rounded, color: textColor.withValues(alpha: 0.54)),
                  prefixText: "+90 ", 
                  prefixStyle: TextStyle(
                    color: (context.read<AuthProvider>().currentUser?.isVerified ?? false) 
                      ? textColor.withValues(alpha: 0.7) 
                      : textColor,
                    fontWeight: FontWeight.bold
                  ),
                  suffixIcon: (context.read<AuthProvider>().currentUser?.isVerified ?? false)
                    ? Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                      )
                    : Container(
                        margin: const EdgeInsets.all(8),
                        width: 20,
                        alignment: Alignment.center,
                        child: Icon(Icons.info_outline_rounded, color: Colors.orange.withValues(alpha: 0.7), size: 20),
                      ),
                  filled: true,
                  // Dim if read-only
                  fillColor: (context.read<AuthProvider>().currentUser?.isVerified ?? false)
                      ? cardColor.withValues(alpha: 0.5) 
                      : cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  helperText: (context.read<AuthProvider>().currentUser?.isVerified ?? false)
                      ? lang.translate('phone_verified_msg')
                      : lang.translate('phone_not_verified_msg'),
                  helperStyle: TextStyle(
                    color: (context.read<AuthProvider>().currentUser?.isVerified ?? false)
                        ? Colors.green.shade700
                        : Colors.orange.shade700, 
                    fontSize: 11
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _buildTextField(controller: _emailController, label: lang.translate('email'), icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9C06A), // Solid bright yellow theme
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3F7F7F7F),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: context.watch<AuthProvider>().isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(lang.translate('save_changes')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    const textColor = Color(0xFF131313);
    const cardColor = Colors.white;
    const primaryBrand = Color(0xFF76410B);
    final lang = context.read<LanguageProvider>();
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      validator: (val) => val == null || val.isEmpty ? lang.translate('fill_all_fields') : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: textColor.withValues(alpha: 0.54)),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryBrand)),
      ),
    );
  }

  Widget _buildDropdownField(LanguageProvider lang) {
    const textColor = Color(0xFF131313);
    const cardColor = Colors.white;

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: cardColor,
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedGender,
        style: const TextStyle(color: textColor),
        borderRadius: BorderRadius.circular(20), 
        decoration: InputDecoration(
          labelText: lang.translate('gender'),
          labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.wc, color: textColor.withValues(alpha: 0.54)),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        items: [
           DropdownMenuItem(value: "male", child: Text(lang.translate('male'))),
           DropdownMenuItem(value: "female", child: Text(lang.translate('female'))),
           DropdownMenuItem(value: "other", child: Text(lang.translate('other_gender'))),
           DropdownMenuItem(value: "", child: Text(lang.translate('wont_share'))),
        ],
        onChanged: (val) {
          setState(() {
            _selectedGender = val;
          });
        },
      ),
    );
  }

  void _showCupertinoDatePicker(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(lang.translate('cancel'), style: TextStyle(color: Colors.red.shade400)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text(lang.translate('ok'), style: const TextStyle(color: Colors.blue)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final maxDate = DateTime(now.year - 12, now.month, now.day);
                  final minDate = DateTime(1900);
                  DateTime initialDate = _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day);
                  if (initialDate.isAfter(maxDate)) initialDate = maxDate;
                  if (initialDate.isBefore(minDate)) initialDate = minDate;
                  return CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    maximumDate: maxDate,
                    minimumDate: minDate,
                    onDateTimeChanged: (date) => setState(() => _selectedBirthDate = date),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(LanguageProvider lang) {
    const textColor = Color(0xFF131313);
    const cardColor = Colors.white;
    final bool isLocked = _selectedBirthDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            lang.translate('birth_date'),
            style: TextStyle(color: const Color(0xFF131313).withValues(alpha: isLocked ? 0.4 : 0.6), fontSize: 12),
          ),
        ),
        GestureDetector(
      onTap: isLocked ? null : () => _showCupertinoDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isLocked ? cardColor.withValues(alpha: 0.5) : cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: isLocked ? textColor.withValues(alpha: 0.3) : textColor.withValues(alpha: 0.54), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedBirthDate == null
                    ? '—'
                    : DateFormat('dd.MM.yyyy').format(_selectedBirthDate!),
                style: TextStyle(
                  color: _selectedBirthDate == null
                      ? textColor.withValues(alpha: 0.4)
                      : isLocked ? textColor.withValues(alpha: 0.5) : textColor,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              isLocked ? Icons.lock_outline : Icons.arrow_forward_ios_rounded,
              size: isLocked ? 20 : 14,
              color: textColor.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    ),
      ],
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
