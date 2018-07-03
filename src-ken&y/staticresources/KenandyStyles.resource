
@media print  {   .noPrint   {  display:none;  } }

/* following is used by print WO picklist  */
body div.printPageLayout {font-family: Arial,Helvetica,sans-serif; font-size:10px;}

.oddClass {background-color:#FFF;}
.evenClass {background-color:gray;}
.headerRow {background-color:#87afc7; color:#FFF;}
.innerheader {background-color:#D5DDF3;}
.maintable {border:1px solid black;}
.grandTotal {background-color:#aaaacc;}
.bomqtyper {text-align:right;}
.printClass {font-size:17px;}
.rowWithLine {border-bottom:1px solid black;}
.reportSubHeader {vertical-align:bottom !important;}
.rowWithWhiteLine {border-bottom:5px solid white;}

/* for visual force custom popup */
 .customPopup {
    background-color: #F8F8F8;
    border-style: solid;
    border-color: #1797c0;
    border-width: 9px;
    left: 50%;
    padding:10px;
    position: absolute;
    z-index: 99;
    width: 800px;
    margin-left: -400px;
    max-height: 600px;
    overflow:auto;
    top:100px;
}

.greySections {   background-color: grey;		}   
.closeButton , .right {		    float: right;		}
.popupButton{			z-index:10000;		}
.popupBackground{
	background-color:black;
	opacity: 0.70;
	position:absolute;
	width: 100%;
	height: 100%;
	top: 0;
	left: 0;
	z-index: 98;
}