<?php	
	
	function console_log( $data ){
  echo '<script>';
  echo 'console.log('. json_encode( $data ) .')';
  echo '</script>';
}

	if(empty($_POST['input_942']) && strlen($_POST['input_942']) == 0)
	{
		return false;
	}
	
	$input_942 = $_POST['input_942'];
	console_log( implode(",",$input_942));

	// Create email	
	$request_body = $input_942;	
	
	$response = http_get("http://127.0.0.1:54320/torrent?link=".$email_body, array("timeout"=>1), $info); // Get message
	
	return true;			
?>
