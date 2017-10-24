namespace WebMigrations.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("positionbackgroundcheck")]
    public partial class positionbackgroundcheck
    {
        [Key]
        [Column(Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int PositionID { get; set; }

        [Key]
        [Column(Order = 1)]
        [StringLength(25)]
        public string BackgroundCheckID { get; set; }

        [Key]
        [Column(Order = 2)]
        [StringLength(25)]
        public string StateProvinceID { get; set; }

        [Key]
        [Column(Order = 3)]
        [StringLength(25)]
        public string CountryID { get; set; }

        public bool Required { get; set; }

        public DateTime CreatedDate { get; set; }

        public DateTime UpdatedDate { get; set; }

        [Required]
        [StringLength(25)]
        public string ModifiedBy { get; set; }

        public bool Active { get; set; }
    }
}
