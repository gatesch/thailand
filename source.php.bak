<?
	$tainted = $HTTP_GET_VARS["foo"];
	$my_var = $tainted . "testing";

	if(strlen(${my_var}) > 10) {
		do_work($x, $my_var);
	}

	include_once "./sink.php";
?>
