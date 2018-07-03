public with sharing abstract class ServiceParam {

    public String requestId; // A reference to attach the messages. Ex: Process Request Id
    public String targetId; // Id of the document the request is targeted at.

    public abstract ServiceParam inflate(Object obj);

}