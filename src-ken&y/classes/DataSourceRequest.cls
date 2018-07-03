global with sharing class DataSourceRequest {
    global integer take { get; set; }
    global integer skip { get; set; }
    global integer page { get; set; }
    global integer pageSize { get; set; }
    global List<SortDescriptor> sortDescriptor { get; set; }
    global Filter filter { get; set; }
    
    global class SortDescriptor {
        global string field { get; set; }
        global string dir { get; set; }
    }
    
    global class Filter {
        global string logic;
        global List<Filter> filters;        
        global string field;
        global Object value;        
        global string operator;
        global boolean ignoreCase = true;
        
        global Filter() {
            filters = new List<Filter>();
        }
    }
}