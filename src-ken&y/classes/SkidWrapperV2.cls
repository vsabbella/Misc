global class SkidWrapperV2 {
    global SKID__c skid { get; set; }
    global List<Serial__c> serials { get; set; } { serials = new List<Serial__c>(); }
    global SkidWrapperV2(SKID__c skid) { this(skid, null); }
    global SkidWrapperV2(SKID__c skid, List<Serial__c> serials) {
        this.skid = skid;
        if (serials != null) this.serials = serials;
    }
}