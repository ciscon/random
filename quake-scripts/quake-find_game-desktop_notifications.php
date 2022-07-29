#!/bin/php
<?php
//desktop notifications for qw games matching the following parameters

$types="4v4 2v2";
$minplayers=1;
$interval=10;


$oldservers=array();
while (1) {
  if (!$list=json_decode(file_get_contents("https://badplace.eu/api/v2/serverbrowser/busy"))) continue;
  $servers=array();
  foreach ($list as $item) foreach (explode(' ',$types) as $type){
    if ((substr($item->Description,0,strlen($type)) == $type)){
      $count=0;
      foreach ($item->Players as $player){
        if (!$player->Spec) $count++;	
      }
      if ($count >= $minplayers) $servers[]=$type .': '.$item->Address. ' ('.$count.')';
    }
  }
  if (count($servers) && $oldservers !== $servers){
    $newstring='';
    foreach ($servers as $server) if (!in_array($server,$oldservers)) $newstring.=$server."\n";
    if ($newstring) exec('notify-send "'.$newstring.'"');
    $oldservers=$servers;
  }
  sleep($interval);
}

?>
