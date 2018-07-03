/* Kendo Global Styles */

/* Hidden element */
.k-hidden {
	display: none;
}

/* Fix conflicting spacing issues with list elements */
.k-widget ul li, ol li, .k-list-container ul li, ol li {
	margin-left: 0 !important;
/*    padding-left: 0.2em !important;  flattens TreeView */
}

/* Hilite row on grid mouseover */
.k-grid table tbody tr:hover {
    background: #e3f3ff;
}

/* Add padding to the kendo numerictextbox */
.k-numerictextbox .k-input {
	width: 97%;
    padding-right: 2px !important;
}

/* Change the dirty flag color to blue */
.k-dirty {
	border-color: blue transparent transparent blue !important;
}

/* Overide default kendo validation tooltip background color */
.k-widget.k-tooltip-validation {
    background-color: #FFF4C9;
    border-color: #FFE79E;
    color: #263248;
}

/* Set the kendo validation tooltip to max width */
html .k-edit-cell .k-tooltip, html .k-grid-edit-row .k-tooltip {
    max-width: 100%;
}

/* Set the kendo validation tooltip position */
.k-widget.k-tooltip-validation .k-callout-n {
    left: 7px;
}

/* Set the z-index to fix the grid validation message overlay issue */
.k-tooltip-validation {
	z-index: 100;
}
		
/* Set the min height style to kendo grid so the built-in grid loading indicator can be displayed while the data is loading */
.k-grid-content {
	min-height: 25px;
}
	
/* Override Kendo Tooltip Popup styles */
.k-widget.k-tooltip.k-popup {
	border-color: #ccc;
	background-color: #428bca;
}

.k-widget.k-tooltip.k-popup .k-callout-w {
  border-right-color: #ccc;
}
	
/* Toolbar filter */
.toolbar-filter {
	float: right;
	padding-right: 5px;
}

/* Kenandy Common Styles */
.page-container {
	position: relative;
}

.message-close-btn {
	padding: 0 1px;
}

.kndy-text-right {
    text-align: right !important;
}

.kndy-text-center {
    text-align: center !important;
}

.kndy-text-left {
    text-align: left !important;
}

.kndy-pull-right {
	float: right !important;
}

.kndy-pull-left {
	float: left !important;
}
.kndy-table {
	width: 100%;
}

.kndy-hidden {
	display: none;
}

.kndy-red {
	color: red;
}

.kndy-green {
	color: green;
}

.kndy-blue {
	color: blue;
}

.kndy-brown {
	color: brown;
}

.kndy-orange {
	color: orange;
}

.kndy-white {
	color: white;
}

.kndy-error {
	color: #D8000C;
    background-color: #FFBABA;
}

.kndy-separator {
	height: 3em;
	border-right: 1px solid #cfcece;
}

.kndy-grid-empty-message {
	color: gray !important;
}

.kndy-required-input {
  position: relative;
  height: 100%;
}

.kndy-required-input .kndy-required-block {
  background-color: #c00;
  position: absolute;
  left: -4px;
  width: 3px;
  top: 1px;
  bottom: 1px;
}

/* Font awesome custom font size */
.fa-lg {
    font-size: 1.5em !important;
}

/* Firefox: Remove the red border/outline for required fields */
:invalid {
  box-shadow: none;
}

:-moz-submit-invalid {
  box-shadow: none;
}

:-moz-ui-invalid {
  box-shadow:none;
}

/* Kendo Grid Toolbar custom button styles */
.grid-column-menu-command {
	display: inline-block;
	vertical-align: middle; 
	background-color: #fff !important;
	border-color: #ccc !important;
}

.grid-column-menu-list span.k-link {
	line-height: 0 !important;
}

/* DetailList widget styles */
.kndy-detail-list {
	
}

.kndy-detail-list th, td {
	vertical-align: top;
}

.kndy-label-column {
    padding-top: 2px;
    padding-right: 10px;
    padding-bottom: 2px;
    padding-left: 2px;
    text-align: right;
    font-size: 91%;
    font-weight: bold;
    color: #4A4A56;
}

.kndy-detail-list .kndy-label-column {
	width: 18%;
}

.kndy-data-column {
    padding-top: 2px;
    padding-right: 2px;
    padding-bottom: 2px;
    padding-left: 10px;
    text-align: left
}

.kndy-detail-list .kndy-data-column {
    width: 32%;
}

ul.kndy-detail-list.k-panelbar {
    border-color: #f8f8f8;
}

ul.kndy-detail-list.k-panelbar li.k-item div.k-content {
    background-color: #f8f8f8;
    border-bottom-width: 0px;
}

ul.kndy-detail-list.k-panelbar li.k-item span.k-link.k-header {
    color: #fff;
    background-color: #428bca;
}

ul.kndy-detail-list.k-panelbar .k-panelbar-expand,
ul.kndy-detail-list.k-panelbar .k-panelbar-collapse {
    right: auto;
    left: 2px;
    top: 15px;
}

ul.kndy-detail-list.k-panelbar h3.kndy-section-title {
	padding-left: 0.5em;
}

ul.kndy-detail-list.k-panelbar .k-icon.k-panelbar-expand, .k-icon.k-panelbar-collapse {
    background-image: none;
    font-family: 'FontAwesome';
    font-size: 1.5em;
    overflow: visible;
}

ul.kndy-detail-list.k-panelbar .k-panelbar-expand::before {
    content: '\f0da';
}

ul.kndy-detail-list.k-panelbar .k-panelbar-collapse::before {
    content: '\f0d7';
}

/* Kenandy DropDownButton styles */
.kndy-dropdown-button {
    display: inline-block;
}

.kndy-dropdown-button .kndy-primary-button {
    border-top-right-radius: 0;
    border-bottom-right-radius: 0;
}

.kndy-dropdown-button .kndy-split-button {
    border-top-left-radius: 0;
    border-bottom-left-radius: 0;
    padding-left: 3px;
    padding-right: 3px;
}

.kndy-dropdown-button .kndy-popup-menu {
    position: absolute;
    z-index: 100;
}

.kndy-dropdown-button .kndy-popup-menu .k-item {
    margin: 0px;
}

.kndy-dropdown-button .kndy-popup-menu .kndy-separator {
    height: 2em;
    cursor: not-allowed;
}

/*Even though we are setting the height to auto, as per Telerik, "Normally, the Grid height should be fixed when using frozen columns. This ensures the Grid is able to calculate and construct its layout properly". Ref: http://docs.telerik.com/kendo-ui/controls/data-management/grid/how-to/Layout/change-grid-height-when-using-frozen-columns */
.k-grid-content-locked{
   height: auto !important;
}