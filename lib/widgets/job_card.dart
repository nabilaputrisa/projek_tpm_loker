import 'package:flutter/material.dart';
import '../data/models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final bool isInWishlist;
  final VoidCallback onTap;
  final VoidCallback onWishlistTap;

  const JobCard({
    super.key,
    required this.job,
    required this.isInWishlist,
    required this.onTap,
    required this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Company & Wishlist
              Row(
                children: [
                  // Company Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primary, // Warna solid
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        job.company.isNotEmpty 
                            ? job.company[0].toUpperCase() 
                            : '?',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Company Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.company,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Wishlist Button
                  IconButton(
                    onPressed: onWishlistTap,
                    icon: Icon(
                      isInWishlist ? Icons.bookmark : Icons.bookmark_border,
                      color: isInWishlist 
                          ? cs.primary 
                          : cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                    tooltip: isInWishlist 
                        ? 'Hapus dari wishlist' 
                        : 'Simpan ke wishlist',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Job Title
              Text(
                job.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: cs.onSurfaceVariant.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Salary
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.primary, // Warna solid
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 14,
                      color: cs.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        job.salaryDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Category (if available)
              if (job.category != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    Chip(
                      label: Text(
                        job.category!,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: cs.primaryContainer,
                      labelStyle: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    ),
                    if (job.contractType != null)
                      Chip(
                        label: Text(
                          job.contractType!,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: cs.secondaryContainer,
                        labelStyle: TextStyle(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}