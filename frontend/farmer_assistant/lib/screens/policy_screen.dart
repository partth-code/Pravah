import 'package:flutter/material.dart';
import '../models/api_models.dart';
import 'package:easy_localization/easy_localization.dart';

class PolicyScreen extends StatefulWidget {
  final List<Policy> policies;
  final bool loading;
  final Function(String) onSearch;

  const PolicyScreen({
    super.key,
    required this.policies,
    required this.loading,
    required this.onSearch,
  });

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSubsidies = false;
  late final List<Policy> _mockSubsidies;

  @override
  void initState() {
    super.initState();
    _mockSubsidies = [
      Policy(
        policyId: 'sub_001',
        title: 'Seed Purchase Subsidy',
        description: 'Get up to 50% subsidy on certified seeds for eligible farmers.',
        eligibility: 'Smallholder farmers with valid ID',
        tags: ['Seeds', 'Kharif'],
        requiredDocs: ['Farmer ID', 'Bank Passbook'],
        states: ['All States'],
      ),
      Policy(
        policyId: 'sub_002',
        title: 'Drip Irrigation Subsidy',
        description: 'Financial support for micro-irrigation systems to save water.',
        eligibility: 'Farmers with up to 5 acres',
        tags: ['Irrigation', 'Water'],
        requiredDocs: ['Land Records', 'Aadhaar'],
        states: ['All States'],
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
                        widget.onSearch('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                  ),
                  onSubmitted: (value) => widget.onSearch(value),
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
              widget.onSearch(suggestions[index].tr());
            },
            backgroundColor: Colors.green.withOpacity(0.1),
            labelStyle: const TextStyle(color: Colors.green),
          ),
        ),
      ),
    );
  }

  // Old wide toggle removed in favor of compact control next to search

  Widget _buildContent() {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _showSubsidies ? _mockSubsidies : widget.policies;

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
                        ),
                        const SizedBox(height: 4),
                        Text(
                          policy.eligibility,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
                spacing: 8,
                children: policy.tags.take(3).map((tag) => Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.blue),
                )).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'policy.required'.tr()}: ${policy.requiredDocs.length} ${'policy.documents'.tr()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _openDetails(policy, isSubsidy: isSubsidy),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(isSubsidy ? 'policy.claim'.tr() : 'policy.apply'.tr()),
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
                      Text(policy.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(policy.eligibility, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('policy.description'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(policy.description),
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
