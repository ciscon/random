#!/bin/php
<?php
//desktop notifications for qw games matching the following parameters

$types="4v4 2v2";
$minplayers=1;
$interval=10;
$source="hub"; //badplace or hub

$oldservers=array();

$types=preg_replace("/[^0-9 ]/", '', $types);
while (1) {
  $servers=array();
  if ($source == "badplace") {
    if (!$list=json_decode(file_get_contents("https://badplace.eu/api/v2/serverbrowser/busy"))) continue;
    foreach ($list as $item) foreach (explode(' ',$types) as $type){
      if ((substr(preg_replace("/[^0-9 ]/", '', $item->Description),0,strlen($type)) == $type)){
        $count=0;
        foreach ($item->Players as $player){
          if (!$player->Spec) $count++;	
        }
        if ($count >= $minplayers) $servers[]=$item->Description.': '.$item->Address. ' ('.$count.')';
      }
    }
  } else {
    if (!$list=json_decode(file_get_contents("https://hubapi.quakeworld.nu/v2/servers/mvdsv"))) continue;
    foreach ($list as $item) foreach (explode(' ',$types) as $type){
      if ((substr(preg_replace('/[^0-9 ]/', '', $item->mode),0,strlen($type)) == $type)){
        $count=$item->player_slots->used;
        if ($count >= $minplayers) $servers[]=$item->mode.': '.$item->address. ' ('.$count.')';
      }
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
