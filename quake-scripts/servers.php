<?php

header('Content-type: text/plain; charset=utf-8');
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

$delimiter=",";
$csv=fopen('servers.txt','r');
while ($row = fgetcsv($csv,null,$delimiter)) $servers[]=$row;

$filters=$_REQUEST['filter']?explode(",",$_REQUEST['filter']):null;

if (is_countable($filters) && count($filters) > 0){
	foreach ($servers as $keyserver=>$server) {
		$found=false;
		if($keyserver == 0) {
			$found=true;
		} else {
			foreach ($server as $value){
				foreach($filters as $filter)
					if (str_contains($value, $filter)) { 
						$found=true;
					}
			}
		}
		if (!$found) {
			unset($servers[$keyserver]);
		}
	}
}
foreach ($servers as $row){
	if($row) echo implode(",",$row)."\n";
}

?>
