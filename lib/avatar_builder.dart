import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ============ AVATAR BUILDER SCREEN ============
class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({super.key});

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  // Avatar options
  String _selectedSeed = '';
  String _skinColor = 'light';
  String _top = 'shortHairShortFlat';
  String _hairColor = 'black';
  String _eyes = 'default';
  String _eyebrows = 'default';
  String _mouth = 'smile';
  String _facialHair = 'blank';
  String _accessories = 'blank';
  String _clothing = 'shirtCrewNeck';
  String _clothesColor = 'blue';
  bool _isSaving = false;

  // Dropdown options
  final List<String> _skinColors = [
    'light', 'mediumLight', 'medium', 'mediumDark', 'dark', 'brown'
  ];
  final List<String> _tops = [
    'shortHairShortFlat', 'shortHairShortRound', 'shortHairShortWaved',
    'shortHairSides', 'shortHairTheCaesar', 'shortHairTheCaesarSidePart',
    'longHairBigHair', 'longHairBob', 'longHairBun', 'longHairCurly',
    'longHairCurvy', 'longHairDreads', 'longHairFrida', 'longHairFro',
    'longHairFroBand', 'longHairNotTooLong', 'longHairShavedSides',
    'longHairMiaWallace', 'longHairStraight', 'longHairStraight2',
    'longHairStraightStrand', 'hat', 'hijab', 'turban', 'winterHat1',
    'winterHat2', 'winterHat3', 'winterHat4', 'eyepatch', 'bald', 'baldSides'
  ];
  final List<String> _hairColors = [
    'auburn', 'black', 'blonde', 'blondeGolden', 'brown', 'brownDark',
    'pastelPink', 'blue', 'platinum', 'red', 'silverGray'
  ];
  final List<String> _eyesOptions = [
    'default', 'closed', 'cry', 'eyeRoll', 'happy', 'hearts', 'side',
    'squint', 'surprised', 'wink', 'winkWacky'
  ];
  final List<String> _eyebrowsOptions = [
    'default', 'angry', 'angryNatural', 'defaultNatural', 'flatNatural',
    'frownNatural', 'raisedExcited', 'raisedExcitedNatural', 'sadConcerned',
    'sadConcernedNatural', 'unibrowNatural', 'upDown', 'upDownNatural'
  ];
  final List<String> _mouthOptions = [
    'default', 'concerned', 'disbelief', 'eating', 'grimace', 'sad',
    'screamOpen', 'serious', 'smile', 'tongue', 'twinkle', 'vomit'
  ];
  final List<String> _facialHairOptions = [
    'blank', 'beardMedium', 'beardLight', 'beardMajestic', 'moustacheFancy',
    'moustacheMagnum'
  ];
  final List<String> _accessoriesOptions = [
    'blank', 'kurt', 'prescription01', 'prescription02', 'round', 'sunglasses', 'wayfarers'
  ];
  final List<String> _clothingOptions = [
    'blazerShirt', 'blazerSweater', 'collarSweater', 'graphicShirt', 'hoodie',
    'overall', 'shirtCrewNeck', 'shirtScoopNeck', 'shirtVNeck'
  ];
  final List<String> _clothesColors = [
    'black', 'blue01', 'blue02', 'blue03', 'gray01', 'gray02', 'heather',
    'pastelBlue', 'pastelGreen', 'pastelOrange', 'pastelRed', 'pastelYellow',
    'pink', 'red', 'white'
  ];

  @override
  void initState() {
    super.initState();
    _generateRandomSeed();
  }

  void _generateRandomSeed() {
    setState(() {
      _selectedSeed = DateTime.now().millisecondsSinceEpoch.toString();
    });
  }

  String get avatarUrl {
    return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$_selectedSeed'
        '&skinColor=$_skinColor'
        '&top=$_top'
        '&hairColor=$_hairColor'
        '&eyes=$_eyes'
        '&eyebrows=$_eyebrows'
        '&mouth=$_mouth'
        '&facialHair=$_facialHair'
        '&accessories=$_accessories'
        '&clothing=$_clothing'
        '&clothesColor=$_clothesColor';
  }

  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'avatarUrl': avatarUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar save ho gaya!')),
        );
        Navigator.pop(context, avatarUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                underline: const SizedBox(),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Apna Avatar Banayein'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Preview
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Live Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: SvgPicture.network(
                      avatarUrl,
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                      placeholderBuilder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _generateRandomSeed,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Naya Avatar Banayein'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Options
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 15),
                  const Text(
                    'Apna Avatar Customize Karein',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Skin Color
                  _buildDropdown('Skin Color', _skinColor, _skinColors, (val) {
                    setState(() => _skinColor = val);
                  }),

                  // Hair Style
                  _buildDropdown('Hair Style', _top, _tops, (val) {
                    setState(() => _top = val);
                  }),

                  // Hair Color
                  _buildDropdown('Hair Color', _hairColor, _hairColors, (val) {
                    setState(() => _hairColor = val);
                  }),

                  // Eyes
                  _buildDropdown('Eyes', _eyes, _eyesOptions, (val) {
                    setState(() => _eyes = val);
                  }),

                  // Eyebrows
                  _buildDropdown('Eyebrows', _eyebrows, _eyebrowsOptions, (val) {
                    setState(() => _eyebrows = val);
                  }),

                  // Mouth
                  _buildDropdown('Mouth', _mouth, _mouthOptions, (val) {
                    setState(() => _mouth = val);
                  }),

                  // Facial Hair
                  _buildDropdown('Facial Hair', _facialHair, _facialHairOptions, (val) {
                    setState(() => _facialHair = val);
                  }),

                  // Accessories
                  _buildDropdown('Accessories', _accessories, _accessoriesOptions, (val) {
                    setState(() => _accessories = val);
                  }),

                  // Clothes
                  _buildDropdown('Clothes', _clothing, _clothingOptions, (val) {
                    setState(() => _clothing = val);
                  }),

                  // Clothes Color
                  _buildDropdown('Clothes Color', _clothesColor, _clothesColors, (val) {
                    setState(() => _clothesColor = val);
                  }),

                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAvatar,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSaving ? 'Saving...' : 'Avatar Save Karein'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ AVATAR WIDGET (Kisi bhi jagah use karne ke liye) ============
class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final double size;

  const AvatarWidget({
    super.key,
    this.avatarUrl,
    required this.username,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: SvgPicture.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => _defaultAvatar(),
        ),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
