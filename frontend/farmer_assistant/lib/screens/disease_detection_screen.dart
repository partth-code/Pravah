import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import '../models/api_models.dart';
import '../services/state_service.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  DiseaseDetection? _detectionResult;
  bool _isProcessing = false;
  late AnimationController _flipController;
  late AnimationController _scanController;
  late Animation<double> _flipAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('disease.title'.tr()),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isProcessing) {
      return _buildProcessingView();
    }

    if (_detectionResult != null) {
      return _buildResultsView();
    }

    return _buildCameraView();
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Background image
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1416879595882-3373a0480b5b?ixlib=rb-4.0.3&auto=format&fit=crop&w=2070&q=80'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
          ),
        ),
        // Content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_flipAnimation.value * 3.14159),
                    child: _flipAnimation.value < 0.5
                        ? _buildCameraButton()
                        : _buildUploadButton(),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'disease.header'.tr(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'disease.hint'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_selectedImage != null) _buildImagePreview(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: () {
        _flipController.forward();
      },
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1FA2FF), Color(0xFF12D8A5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: const Icon(
          Icons.search,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: () async {
        await _pickImageFromGallery();
        // Don't reverse the flip controller as we want to show the overlay
      },
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF12D8A5), Color(0xFF1FA2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: const Icon(
          Icons.upload,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.upload),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _processImage,
                icon: const Icon(Icons.search),
                label: const Text('Detect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                Lottie.asset(
                  'assets/lottie/scan.json',
                  repeat: true,
                  animate: true,
                  width: 220,
                  height: 220,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'disease.analyzing'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'disease.wait'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image card at the top
          if (_selectedImage != null) _buildImageCard(),
          if (_selectedImage != null) const SizedBox(height: 16),
          
          _buildDetectionSummary(),
          const SizedBox(height: 24),
          _buildDiseaseLabels(),
          const SizedBox(height: 24),
          _buildRemediesSection(),
          const SizedBox(height: 24),
              _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedImage!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDetectionSummary() {
    final topResult = _detectionResult!.labels.isNotEmpty
        ? _detectionResult!.labels.first
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: topResult?.confidence != null && topResult!.confidence > 0.7
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    topResult?.confidence != null && topResult!.confidence > 0.7
                        ? Icons.warning
                        : Icons.check_circle,
                    color: topResult?.confidence != null && topResult!.confidence > 0.7
                        ? Colors.red
                        : Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topResult?.tag.replaceAll('_', ' ').toUpperCase() ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${((topResult?.confidence ?? 0) * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              topResult?.confidence != null && topResult!.confidence > 0.7
                  ? 'Disease detected! Follow the treatment recommendations below.'
                  : 'Plant appears healthy. Continue monitoring for any changes.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseLabels() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detection Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._detectionResult!.labels.map((label) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label.tag.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: label.confidence > 0.7
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(label.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: label.confidence > 0.7 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRemediesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Treatment Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Organic'),
                      Tab(text: 'Chemical'),
                    ],
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildRemedyList('organic'),
                        _buildRemedyList('chemical'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemedyList(String type) {
    final remedies = _detectionResult!.remedies.where((r) => r.type == type).toList();
    
    if (remedies.isEmpty) {
      return const Center(
        child: Text(
          'No organic remedies available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: remedies.length,
      itemBuilder: (context, index) {
        final remedy = remedies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      type == 'organic' ? Icons.eco : Icons.science,
                      color: type == 'organic' ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: type == 'organic' ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...remedy.steps.map((step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(step)),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science, size: 16),
                      const SizedBox(width: 8),
                      Text('Dosage: ${remedy.dosage}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetDetection,
            icon: const Icon(Icons.refresh),
            label: const Text('Detect Another'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveToHistory,
            icon: const Icon(Icons.save),
            label: const Text('Save to History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      print('Opening camera...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        print('Image captured: ${image.path}');
        setState(() {
          _selectedImage = File(image.path);
        });
        // Trigger processing immediately after image capture
        _processImage();
      } else {
        print('No image captured from camera');
      }
    } catch (e) {
      print('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      print('Opening gallery...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        print('Image selected: ${image.path}');
        setState(() {
          _selectedImage = File(image.path);
        });
        // Trigger processing immediately after image selection
        _processImage();
      } else {
        print('No image selected from gallery');
      }
    } catch (e) {
      print('Error selecting image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) {
      print('Error: No image selected for processing');
      return;
    }

    print('Starting image processing...');
    
    setState(() {
      _isProcessing = true;
    });

    _scanController.repeat();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 3));
      
      print('Creating mock detection result...');
      
      // Mock detection result
      final result = DiseaseDetection(
        labels: [
          DiseaseLabel(tag: 'leaf_blight', confidence: 0.82),
          DiseaseLabel(tag: 'rust', confidence: 0.12),
          DiseaseLabel(tag: 'healthy', confidence: 0.06),
        ],
        remedies: [
          DiseaseRemedy(
            type: 'organic',
            steps: ['Neem spray 3%', 'Isolate infected leaves', 'Improve air circulation'],
            dosage: '2 L/acre',
          ),
          DiseaseRemedy(
            type: 'chemical',
            steps: ['Copper oxychloride spray', 'Apply every 7-10 days'],
            dosage: '1.5 g/L',
          ),
        ],
      );

      print('Mock result created successfully');

      setState(() {
        _detectionResult = result;
        _isProcessing = false;
      });

      _scanController.stop();
      print('Image processing completed successfully');
    } catch (e) {
      print('Error during image processing: $e');
      setState(() {
        _isProcessing = false;
      });
      _scanController.stop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detection failed: $e')),
        );
      }
    }
  }

  void _resetDetection() {
    setState(() {
      _selectedImage = null;
      _detectionResult = null;
      _isProcessing = false;
    });
    _flipController.reset();
    _scanController.reset();
  }

  void _saveToHistory() {
    // TODO: Implement save to history
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to history')),
    );
  }
}
