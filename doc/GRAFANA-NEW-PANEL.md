# Creating a new Grafana panel

## 1. Introduction

To create a new query and dashboard panel/visualisation it’s possible to start with a new/blank query or to duplicate
an existing query/panel and then modify it to suit.

To create a new query, click on the ‘Add panel’ button in the top right of the screen.

![add panel](img/grafana-add-panel.png)

Then select ‘Add Query’ or ‘Choose Visualization’ – either will work as they can be easily switched between during the
configuration.

![new panel](img/grafana-new-panel.png)

A new/blank Queries page shown below;

![queries blank](img/grafana-queries-blank.png)

To duplicate an existing query/panel click on the dropdown next to the panel name, then hover over ‘More’ and select ‘Duplicate’.

![panel duplicate](img/grafana-panel-duplicate.png)

Once a new panel is created, click on the dropdown next to the panel name, and then select ‘Edit’ to open the Queries page.

Dashboard setup and configuration is completed within the ‘Queries’, ‘Visualization’ and ‘General’ settings pages, as
described in the following sections.


## 2. Queries
All available Venus OS parameters/measurements are stored in InfluxDB using modified MQTT topics – with the Portal ID and
instance number removed from the MQTT path and available as an independent filter "tag". The installation name (if available)
is another useful filter “tag” available.

Every accessible parameter/measurement in the Venus OS has an associated dbus path which can be searched for in Grafana
and selected as the data source to monitor/display.

The first section of the path refers to the dbus service name (the data source/device) and the remainder is the rest of
the string is the dbus object path.

Some Venus OS dbus path examples are;
- battery/Dc/0/Voltage
-	solarcharger/State
-	vebus/Ac/Out/L1/P
-	system/Relay/0/State

The main configuration of each dashboard visualisation/panel is performed within the Queries page, which has multiple
fields to query for the specific data required and options related to the data interpretation and presentation.

A brief explanation of each section is provided below.

### 2.1 Queries - FROM
![queries from](img/grafana-queries-from.png)

A) The database to query - normally select 'default' (or as shown in the 'Queries to' dropdown above).

B) The dbus path - search for and select the desired parameter.

The required dbus path for the parameter/measurement can be typed in directly (if the exact path is known) or easily
searched for and selected directly in Grafana.

Since the complete list of dbus path is extensive, particularly if the required dbus arrangement is not well known it’s
best to search for the dbus service name (all in lower case) and then scroll through the list to find the required
parameter/measurement.

![queries search service](img/grafana-queries-search-service.png)

Unfortuantly Grafana currently has a limitation where the inbuilt search function is limited to a maximum of 100 search
results, meaning that for some dbus services with over 100 paths (such as ‘settings’ and ‘vebus’), not all available paths
will be shown in the list and further filtering may be required. A
[GitHub issue](https://github.com/victronenergy/venus-docker-grafana/issues/8)
has recently been created to increase the search limit to 250 lines in order to avoid this situation.

The common dbus service names are;
-	battery
-	charger
-	digital input
-	generator
-	genset
-	gps
-	grid
-	inverter
-	meteo
-	pump
-	pvinverter
-	settings
-	solarcharger
-	system
-	tank
-	temperature
-	vebus

The other effective option is to search directly for the desired parameter/measurement using a single word with a capital
first letter (as the search is case sensitive and all sub-paths use a capital first letter for each word).

![queries search dbus](img/grafana-queries-search-dbus.png)

Note that for the search feature to work there must not be an 'instanceNumber' WHERE condition, if one exists it needs
to be removed and re-added later.

To better familiarise yourself with the Venus OS dbus path structure refer to the [dbus path list](https://github.com/victronenergy/venus/wiki/dbus) in GitHub or the [modbus TCP register list](https://www.victronenergy.com/support-and-downloads/whitepapers) in the whitepapers section of the Victron website.

### 2.2 Queries - WHERE

![queries where](img/grafana-queries-where.png)

This is the section the filter tags are added to ensure that the data is queried from the correct installation and also
the correct device in the installation.

Particularly when there are multiple installations linked to the same Grafana instance and/or with larger systems
(that have multiple devices of the same kind) it is vital to set this section up correctly to ensure that the data
displayed is accurate and not coming from multiple sources (as a combined total) or an unintended source.


A) Add either a ‘portalId’ or ‘name’ tag to define the installation to query – then select/enter the desired portal ID or
installation name to query for data.

The installation ‘name’ tag is most versatile as it’s possible to specify a dynamic name with '=~ /^$name$/' - this
automatically ensures that the data comes from the 'name' of the installation selected at the top left of the dashboard,
enabling the same dashboard to monitor multiple sites without the need for any further updates.

![where tags](img/grafana-where-tags.png)

B) Add the ‘instanceNumber’ filter tag where appropriate – then select/enter the desired device instance' number to query for data.

This filter tag is vital when multiple devices of the same kind exist in the system to avoid confusion between data from multiple
devices that share the same dbus paths.

To identify the correct number for a particualr device, use the GX device to check for the device instance number under
'Device List'>'XYZ device'>'Device Instance'.

![venus device instance](img/grafana-venus-device-instance.png)

### 2.3 Queries - SELECT

![queries select](img/grafana-queries-select.png)

A) The data type - Retain the default settings of 'field(value)'.

B) The data usage/interpretation – normally select 'mean()' (in the Aggregations menu) which provides a short term data average
or ‘last ()’ (in the Selectors menu) to simply use the last known value.

### 2.4 Queries - GROUP BY

![queries group by](img/grafana-queries-group-by.png)

A) The time interval to group individual data points - normally select '$__interval' to display data at full resolution or if
desired (such as to smooth fluctuating data) an alternative time interval can be selected to group individual data points
and present a combined value.

B) The data interpretation between individual data points – normally select 'fill(previous)' to display the last value between
data points/eliminate gaps in the data or for some measurements 'fill(linear)' may be preferred which plots a linear line
between data points/gaps between data.
For data plots it is essential to provide a fill direction other than fill(null) to eliminate gaps between data points.

Example with fill(null) between data points;

![fill null](img/grafana-fill-null.png)

Example with fill(linear) between data points;

![fill null](img/grafana-fill-linear.png)

This is an example of a completed Queries page where two different (but related) dbus paths are displayed in a single graph;

![queries multiple](img/grafana-queries-multiple.png)

## 3. Visualization
To select or change the type of panel/visualization, enter the Visualization page and then click on the Visualization dropdown
to reveal all the available options.

![visualization](img/grafana-visualization.png)

Further configuration of the panel/visualization selected is also completed from the Visualization and there are extensive
customisation options available.
This is an example of a completed Visualization page where two different (but related) dbus paths are displayed in a single
graph (each on a different axis);

![visualization settings](img/grafana-visualization-settings.png)

## 4. General
The title of the panel/visualisation is entered in the general page.

![general](img/grafana-general.png)
