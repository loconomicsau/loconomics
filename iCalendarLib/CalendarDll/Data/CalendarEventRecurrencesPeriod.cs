//------------------------------------------------------------------------------
// <auto-generated>
//    Este código se generó a partir de una plantilla.
//
//    Los cambios manuales en este archivo pueden causar un comportamiento inesperado de la aplicación.
//    Los cambios manuales en este archivo se sobrescribirán si se regenera el código.
// </auto-generated>
//------------------------------------------------------------------------------

namespace CalendarDll.Data
{
    using System;
    using System.Collections.Generic;
    
    public partial class CalendarEventRecurrencesPeriod
    {
        public int IdRecurrence { get; set; }
        public System.DateTime DateStart { get; set; }
        public Nullable<System.DateTime> DateEnd { get; set; }
    
        public virtual CalendarEventRecurrencesPeriodList CalendarEventRecurrencesPeriodList { get; set; }
    }
}
