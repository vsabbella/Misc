/**
 * @description Schedule MRP V2 app
 * Process Job should have company and/or facility 
 * 
 */ 
public class MRPV2Scheduler implements Queueable, Process.Runnable2, Database.AllowsCallouts {
    MRP_Run__c mrpRun;
    Process_Job__c job;
    
    public MRPV2Scheduler () {
    }
    
    public MRPV2Scheduler ( Process_Job__c job ) {
        this.job = job;
        if ( job == null ) {
            throw new SkidService3.SkidService3Exception('Invalid Process Job');
        } else if ( job.Facility__c != null ) {
            GenerateMRPbyFacilityExtV2 mrpJob = new GenerateMRPbyFacilityExtV2 ( job.Facility__c );
            mrpRun = mrpJob.createMRPRun ();
            mrpJob.mrpSemaphore();
        } else if ( job.Company__c != null ) {
            GenerateMRPExtV2 mrpJob = new GenerateMRPExtV2 ( job.Company__c );
            mrpRun = mrpJob.createMRPRun ();
            mrpJob.mrpSemaphore();
        } else {
            // Error
        }
    }
    
    public void execute(QueueableContext context) {
        try {
            MRPService.startMRPGenerate (mrpRun.id) ;
        } catch (Exception e) {
            // TODO Notify class support for QueueableContext
            job.Exception__c = e.getMessage();
            update job;
        }
        MasterControlProgram.finishedBatch( this );
    }
    
    public void runBatch( Process_Job__c job ) {
        ID jobID = System.enqueueJob(new MRPV2Scheduler(job ));
    }
}