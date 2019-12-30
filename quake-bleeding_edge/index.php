<?php

/*
 *
 * directory structure layout
 *
 * quake directory:
 * 	run:
 * 		quake_port27500.sh
 * 	scripts:
 * 		start_servers.sh
 * 		stop_servers.sh
 * 		status.sh
 * 	qw/maps:
 * 		*must be readable/writable by apache user/group
 *
 * */
$quakedir="/opt/quake-bleeding";
$logfile="bleeding_log.txt";
$admin_user='bleederadmin';
$self_uri=strtok($_SERVER["REQUEST_URI"],'?');
global $quakedir, $logfile, $viewonly;


$viewonly=true;
if ($_SERVER['PHP_AUTH_USER'] === $admin_user){
	$viewonly=false;
}else{
	if ($_GET['action'] && $_GET['action'] !== 'status'&& $_GET['action'] !== 'getlog'){
		$_GET['action']=null;
	}
	$_FILES=null;
}

function getstatus(&$status,&$output,$port=null){
	global $quakedir;
	$status=1;
	exec($quakedir.'/scripts/status.sh '.$port,$output,$status);
	$output='<font color=red>'.implode("\n",$output).'</font>';
}

function showlog(){
	$row = 1;
	$maxrows=25;
	$revseredata=array();
	$result=null;
	global $logfile, $viewonly;

	if (($handle = fopen($logfile, "r")) !== FALSE) {

		$result.='<center><table>';
		$result.='<thead style="font-weight: bold;" width=100%><tr width=100%><td>time</td><td>user ip</td><td>action</td><td>status</td></tr></thead>';

		while ((($data = fgetcsv($handle, 1000, '|')) !== FALSE) && ($row < $maxrows)) {
			$num = count($data);
			$reversedata[]=$data;
		}

		$reversedata=array_reverse($reversedata);

		foreach($reversedata as $data){
			$result.='<tr width=100%>';

			for ($c=0; $c < $num; $c++) {
				if(empty($data[$c])) {
					$value = "&nbsp;";
				}else{
					$value = $data[$c];
				}
				if($viewonly && $c == 1) $value='N/A';
				$result.='<td>'.$value.'</td>';
			}

			$result.='</tr>';
			$row++;
		}

		$result.='</tbody></table></center>';
		fclose($handle);
	}
	echo $result;
}

$_user=$_SERVER['HTTP_X_REAL_IP'] ? $_SERVER['HTTP_X_REAL_IP'] : $_SERVER['HTTP_X_CLIENT_IP'];
$_date=date('m/d/y H:i:s', time());

if ($_FILES["file"]["name"]){

	$_action='uploaded file: '.$_FILES["file"]["name"];

	$target_file = $quakedir."/qw/maps/". basename($_FILES["file"]["name"]);
	$uploadOk = 1;
	$filetype = strtolower(pathinfo($target_file,PATHINFO_EXTENSION));
	$_status = 'unknown';

	if($filetype !== 'bsp') {
		$uploadOk = 0;
		$_status = 'file not a bsp';
		echo "File not a bsp.\n";
	} else {
		$_status = 'file uploaded';
		$uploadOk = 1;
	}
	if (file_exists($target_file)) {
		$_status = 'file uploaded but already exists';
		echo "Sorry, file already exists.\n";
		$uploadOk = 0;
	}

	if (!$_FILES["file"]["tmp_name"]){
		$_status='file upload incomplete, perhaps it is larger than '.ini_get("upload_max_filesize").'?';
		$uploadOk = 0;
	}
	if ($uploadOk == 0) {
		echo "Upload failed.";
	} else {
		if (move_uploaded_file($_FILES["file"]["tmp_name"], $target_file)) {
			echo "The file ". basename( $_FILES["file"]["name"]). " has been uploaded.\n";
			exec('/opt/bin/bsputil --check "'.$target_file.'" 2>&1',$output,$status);
			if ($status != 0){
				$_status = 'file uploaded and moved to map directory, but there were bsputil errors';
				echo "\nBSP Invalid!\n";
				echo "\nbsputil output:\n".implode("\n",$output);
			} else {
				if(count($output)){
					$_status = 'file uploaded and moved to map directory successfully';
					echo "\nbsputil output:\n".implode("\n",$output);
				}
			}
		} else {
			$_status = 'file uploaded but could not be moved to maps directory';
			echo "Sorry, there was an error uploading your file.";
		}
	}

	//update log
	file_put_contents($logfile, $_date.'|'.$_user.'|'.$_action.'|'.$_status.PHP_EOL , FILE_APPEND | LOCK_EX);
	exit;
}


if ($_GET['action']){

	$action=$_GET['action'];
	$_action='action: '.$action;
	$_status='none';
	$_port=(int)$_GET['port'];
	$nolog=false;

	if ($_action === 'action: getlog') { showlog(); exit(0); }

	echo "<center><pre>";

	exec($quakedir.'/scripts/status.sh '.$_port,$output,$status);
	if ($action == 'status'){
		$nolog=true; //don't log status requests
		$output='<font color=red>'.implode("\n",$output).'</font>';
	} else if ($action == 'start'){
		if ($status == 1){echo 'Already running, not doing anything.';exit;}
		$output=shell_exec($quakedir.'/scripts/start_servers.sh '.$_port);
	} else {
		if ($status == 0 ){echo 'Already stopped.  Doing it anyway.';exit;}
		$output=shell_exec($quakedir.'/scripts/stop_servers.sh '.$_port);
	}

	echo "$output";

	if (!$nolog) {
		//update log
		file_put_contents($logfile, $_date.'|'.$_user.'|'.$_action.'|'.$_status.PHP_EOL , FILE_APPEND | LOCK_EX);
	}
	exit;
}




echo '<html>

<head>

<style>
body {
	font-size:12px;
	font-family:monospace,monospace;
}

table {
	table-layout: auto;
margin:0;
padding:0;
border:0;
       max-width: 99%;
       font-size:10px;
       font-family:monospace,monospace;
       border-spacing:0px;
       border-collapse:collapse;
}
td {
border: solid thin #a1a1a1;
}
thead {
border: solid thin #a1a1a1;
	background-color: #a1a1a1;
}
</style>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<title>Quake server control</title>
<script src="/js/jquery-3.3.1.min.js" type="text/javascript"></script>

<script>


function updatelog(){
	$.ajax({url: "'.$self_uri.'?action=getlog", success: function(result){
			$("#log").html(result);
			},
error: function(){
}

});
}

function updatestatus (action, port) {
	$("input").prop("disabled",true);
	$("button").prop("disabled",true);
	$("#header").html("<center><b>Updating...</b></center>");
	$("#status").html("<center>...</center>");
	$.ajax({url: "'.$self_uri.'?action="+action+"&port="+port, success: function(result){
			$("#status").html(result);
			updatelog();
			setTimeout(
					function() {
					$.ajax({url: "'.$self_uri.'?action=status", 
							success: function(result){
							$("#status").append(result);
							$("#header").html("<center><b>Server Status</b></center>");
							updatelog();
							},
error: function(){
alert("failure.");
updatelog();
$("input").prop("disabled",false);
$("button").prop("disabled",false);
}
});
					$("input").prop("disabled",false);
					$("button").prop("disabled",false);
					}, 1500);
}});
}
</script>


<style>
body
{color:#2a2a2a;background-color:#d8d8d8;padding:0;margin:0;}
.center {
margin: auto;
width: 720px;
border: 3px solid grey;
padding: 10px;
}
div#uploadoutput{
	background-color:#000;
color:#fff;
margin:0px;
padding:20px;
display:none;
}
div#header{background-color:#a1a1a1}
div#light{background-color:#d8d8d8;padding-top:12px;padding-bottom:5px;margin:10px;}
div#control{background-color:#a1a1a1}
</style>

</head>

<body>
<br>
<div class=center id="header">
<center><b>Current Status</b>
</div>
<div class=center id="status"><center>';

getstatus($status,$output);

echo "<pre>";
echo $output;

echo "</pre>";

echo '</center></div>';

if(!$viewonly){

	$scripts=glob("$quakedir/run/*.sh");
	foreach($scripts as $index=>$script){
		echo '<div id=control class=center><center>';
		preg_match('/[0-9]+/',basename($script),$port);
		echo "<input onclick='updatestatus(\"start\",".$port[0].");' id=start type=button value='Start Server ".$port[0]."'>";
		echo "&nbsp&nbsp";
		echo "<input onclick='updatestatus(\"stop\",".$port[0].");' id=stop type=button value='Stop Server ".$port[0]."'>";
		echo '</center></div>';
	}


	echo '<br>
		<div id=header class=center><center>
		<b>Upload Map</b>
		<div id=light><center>
		<input id="mapupload" type="file" name="mapup" />
		<button id="upload">Upload</button>
		<script>
		$(\'#upload\').on(\'click\', function() {
				var file_data = $(\'#mapupload\').prop(\'files\')[0];   
				if (file_data){
				var form_data = new FormData();                  
				form_data.append(\'file\', file_data);
				$("input").prop("disabled",true);
				$("button").prop("disabled",true);
				$.ajax({
url: \'index.php\',
dataType: \'text\',
cache: false,
contentType: false,
processData: false,
data: form_data,                         
type: \'post\',
success: function(response){
$(\'#uploadoutput\').show();
$(\'#uploadoutput\').html(response);
updatelog();
$("input").prop("disabled",false);
$("button").prop("disabled",false);
},
error: function(){
alert("failure.");
updatelog();
$("input").prop("disabled",false);
$("button").prop("disabled",false);
}
});
}
});
</script>
<div><center><pre><div id=uploadoutput>
</div></pre></center></div>
</center></div>

<div><center><div class=light>
<font color=black>Note: After uploading a map users should just have to reconnect to download new map aliases, if they do not, maps they vote for (eg /ultrav) will be the wrong map.  If all else fails or the server gets into a broken state for some other reason, just stop and start the server.</font>
</center></div>
</div>';

}

echo '
<br>
<div class=center id="header">
<center><b>Recent Log</b>
</div>
<div class=center id="log">';



echo '
</div>
<script>updatelog();</script>
</body></html>';

?>
