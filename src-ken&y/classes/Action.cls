/**
 * Created by ryansieve on 4/12/17.
 */

global class Action {

    global Interface Target{
        Response execute(Object obj);
    }

    global class Response{
        global boolean success;
        global Map<String, Object> results;
        global Map<String, Object> error;
        global Result result;

        global Response(){
            this.results = new Map<String, Object>();
            this.error = new Map<String, Object>();
            this.result = new Result();
        }
    }

    global class Result{
        global Object resultObject;
    }
}