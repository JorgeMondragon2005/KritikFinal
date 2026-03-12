using System;

namespace Kritik.Shared.Models
{
    public class ProjectRankingDTO
    {
        public string ProjectId { get; set; } = null!;
        public string TeamName { get; set; } = null!;
        public string Category { get; set; } = null!;
        public double AverageScore { get; set; }
        public int TotalVotes { get; set; }
        public double IntegrityRate { get; set; } // 0.0 to 1.0 (Percentage of valid/complete data)
    }
}
