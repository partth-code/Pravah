import 'package:flutter/material.dart';
import '../models/api_models.dart';
import 'package:easy_localization/easy_localization.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSubsidies = false;
  late final List<Policy> _mockSubsidies;
  late final List<Policy> _mockPolicies;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    _mockPolicies = [
      Policy(
        policyId: 'p1',
        title: 'PM Kisan Samman Nidhi',
        description: 'Direct income support scheme providing ₹6,000 per year to all landholding farmer families across the country.',
        eligibility: 'All landholding farmer families with cultivable land',
        requiredDocs: [
          'Aadhaar Card',
          'Land Records',
          'Bank Account Details',
          'Mobile Number'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Income Support', 'Direct Benefit Transfer', 'Annual Payment'],
        applicationDeadline: 'Ongoing',
        benefits: '₹6,000 per year in 3 installments',
        contactInfo: '1800-180-1551',
        website: 'https://pmkisan.gov.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p2',
        title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
        description: 'Crop insurance scheme providing financial support to farmers in case of crop failure due to natural calamities.',
        eligibility: 'All farmers growing notified crops in notified areas',
        requiredDocs: [
          'Land Records',
          'Crop Details',
          'Bank Account Details',
          'Aadhaar Card'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Crop Insurance', 'Natural Calamities', 'Premium Subsidy'],
        applicationDeadline: 'Before sowing season',
        benefits: 'Up to 100% premium subsidy for small farmers',
        contactInfo: '1800-180-1551',
        website: 'https://pmfby.gov.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p3',
        title: 'Soil Health Card Scheme',
        description: 'Scheme to provide soil health cards to farmers with recommendations for appropriate use of fertilizers.',
        eligibility: 'All farmers with agricultural land',
        requiredDocs: [
          'Land Records',
          'Aadhaar Card',
          'Mobile Number'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Soil Testing', 'Fertilizer Recommendation', 'Sustainable Farming'],
        applicationDeadline: 'Ongoing',
        benefits: 'Free soil testing and recommendations',
        contactInfo: '1800-180-1551',
        website: 'https://soilhealth.dac.gov.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p4',
        title: 'Kisan Credit Card (KCC)',
        description: 'Credit card scheme for farmers to meet their short-term credit requirements for cultivation.',
        eligibility: 'All farmers including tenant farmers and oral lessees',
        requiredDocs: [
          'Land Records',
          'Aadhaar Card',
          'Bank Account Details',
          'Income Certificate'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Credit Card', 'Short-term Credit', 'Low Interest'],
        applicationDeadline: 'Ongoing',
        benefits: 'Up to ₹3 lakh credit at 4% interest',
        contactInfo: 'Contact nearest bank branch',
        website: 'https://www.rbi.org.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p5',
        title: 'Pradhan Mantri Kisan Sampada Yojana',
        description: 'Scheme for creation of modern infrastructure for food processing sector.',
        eligibility: 'Food processing units, entrepreneurs, and farmers',
        requiredDocs: [
          'Project Proposal',
          'Land Documents',
          'Financial Statements',
          'Technical Details'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Food Processing', 'Infrastructure', 'Modernization'],
        applicationDeadline: 'As per notification',
        benefits: 'Up to 50% subsidy on project cost',
        contactInfo: '1800-180-1551',
        website: 'https://mofpi.nic.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'p6',
        title: 'National Mission for Sustainable Agriculture',
        description: 'Mission to promote sustainable agriculture through climate change adaptation and mitigation measures.',
        eligibility: 'Farmers practicing sustainable agriculture',
        requiredDocs: [
          'Land Records',
          'Crop Details',
          'Sustainability Practices Documentation'
        ],
        states: ['All States', 'Union Territories'],
        tags: ['Sustainable Agriculture', 'Climate Change', 'Environment'],
        applicationDeadline: 'Ongoing',
        benefits: 'Financial assistance for sustainable practices',
        contactInfo: '1800-180-1551',
        website: 'https://nmsa.dac.gov.in',
        status: 'Active',
      ),
    ];

    _mockSubsidies = [
      Policy(
        policyId: 'sub_001',
        title: 'Seed Purchase Subsidy',
        description: 'Get up to 50% subsidy on certified seeds for eligible farmers.',
        eligibility: 'Smallholder farmers with valid ID',
        tags: ['Seeds', 'Kharif'],
        requiredDocs: ['Farmer ID', 'Bank Passbook'],
        states: ['All States'],
        applicationDeadline: 'Ongoing',
        benefits: 'Up to 50% subsidy on certified seeds',
        contactInfo: 'Contact local agriculture office',
        website: 'https://agriculture.gov.in',
        status: 'Active',
      ),
      Policy(
        policyId: 'sub_002',
        title: 'Drip Irrigation Subsidy',
        description: 'Financial support for micro-irrigation systems to save water.',
        eligibility: 'Farmers with up to 5 acres',
        tags: ['Irrigation', 'Water'],
        requiredDocs: ['Land Records', 'Aadhaar'],
        states: ['All States'],
        applicationDeadline: 'Ongoing',
        benefits: 'Up to 90% subsidy for small farmers',
        contactInfo: 'Contact local agriculture office',
        website: 'https://agriculture.gov.in',
        status: 'Active',
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('policy.title'.tr()),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'policy.search_hint'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _handleSearch('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                  ),
                  onSubmitted: (value) => _handleSearch(value),
                ),
              ),
              const SizedBox(width: 12),
              _ModeToggle(
                showSubsidies: _showSubsidies,
                onChanged: (v) => setState(() => _showSubsidies = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickSuggestions(),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      'policy.quick_suggestions.seed_subsidy',
      'policy.quick_suggestions.irrigation',
      'policy.quick_suggestions.crop_insurance',
      'policy.quick_suggestions.weather_alert'
    ];
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(suggestions[index].tr()),
            onPressed: () {
              _searchController.text = suggestions[index].tr();
              _handleSearch(suggestions[index].tr());
            },
            backgroundColor: Colors.green.withOpacity(0.1),
            labelStyle: const TextStyle(color: Colors.green),
          ),
        ),
      ),
    );
  }

  void _handleSearch(String query) {
    setState(() {
      _loading = true;
    });
    
    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _loading = false;
      });
    });
  }

  List<Policy> _getFilteredItems() {
    final items = _showSubsidies ? _mockSubsidies : _mockPolicies;
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      return items;
    }
    
    return items.where((policy) {
      return policy.title.toLowerCase().contains(query) ||
             policy.description.toLowerCase().contains(query) ||
             policy.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _getFilteredItems();

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index], _showSubsidies),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.policy,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'policy.empty_title'.tr(),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'policy.empty_sub'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Policy policy, bool isSubsidy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openDetails(policy, isSubsidy: isSubsidy),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isSubsidy ? Colors.amber : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          policy.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          policy.eligibility,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                policy.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: policy.tags.take(3).map((tag) => Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.blue),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${'policy.required'.tr()}: ${policy.requiredDocs.length} ${'policy.documents'.tr()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _openDetails(policy, isSubsidy: isSubsidy),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      isSubsidy ? 'policy.claim'.tr() : 'policy.apply'.tr(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(Policy policy, {required bool isSubsidy}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PolicyDetailPage(policy: policy, isSubsidy: isSubsidy),
    ));
  }
}

class _ModeToggle extends StatelessWidget {
  final bool showSubsidies;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.showSubsidies, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!showSubsidies),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(showSubsidies ? Icons.payments : Icons.policy, size: 18, color: Colors.green),
            const SizedBox(width: 6),
            Text(showSubsidies ? 'policy.subsidies'.tr() : 'policy.policies'.tr(), style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Switch(
              value: showSubsidies,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyDetailPage extends StatelessWidget {
  final Policy policy;
  final bool isSubsidy;
  const _PolicyDetailPage({required this.policy, required this.isSubsidy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isSubsidy ? 'policy.subsidy_details'.tr() : 'policy.policy_details'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(isSubsidy ? Icons.payments : Icons.policy, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.title, 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        policy.eligibility, 
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('policy.description'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              policy.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text('policy.required_docs'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...policy.requiredDocs.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 16), const SizedBox(width: 6), Text(d)]),
                )),
            const SizedBox(height: 16),
            Text('policy.how_to_apply'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _RedeemSteps(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.bookmark_border), label: Text('policy.bookmark'.tr()))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send),
                    label: Text(isSubsidy ? 'policy.claim_now'.tr() : 'policy.apply_now'.tr()),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _RedeemSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = const [
      'policy.steps.check_eligibility',
      'policy.steps.prepare_docs',
      'policy.steps.fill_form',
      'policy.steps.submit',
      'policy.steps.track_status',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps
          .map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [const Icon(Icons.radio_button_checked, size: 16, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(s.tr()))]),
              ))
          .toList(),
    );
  }
}
