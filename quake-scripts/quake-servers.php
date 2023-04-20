<?php
/*
apache htaccess rules:
RewriteCond %{REQUEST_URI} !quake-servers.php.*
RewriteRule ^servers-antilag.*([^?]*)$ /quake-servers.php?$1&antilag=1 [L,QSA]
RewriteRule ^servers.*([^?]*)$ /quake-servers.php?$1 [L,QSA]
*/

header('Content-type: text/plain; charset=utf-8');
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

$filters=isset($_REQUEST['filter'])?explode(",",$_REQUEST['filter']):null;
$antilag=isset($_REQUEST['antilag'])?true:false;

$delimiter=",";
if ($antilag) {
	$file='servers-antilag.txt';
} else {
	$file='servers.txt';
}

if (!file_exists($file)) exit(1);
$csv=fopen($file,'r');
$header = fgetcsv($csv,null,$delimiter);

while ($row = fgetcsv($csv,null,$delimiter)) $servers[]=$row;


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
sort($servers);
echo implode(",",$header)."\n";
foreach ($servers as $row){
	if($row) echo implode(",",$row)."\n";
}

?>
