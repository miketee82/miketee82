<?php
// Please update the following variables:
$apikey = "XXX-usX";
$listid = "XXX";
$apiurl = "https://usX.api.mailchimp.com/3.0/";

function mc_request( $api, $type, $target, $data = false ) {
    $auth = base64_encode( 'user:'.$apikey );

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $api['url'].$target);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json', 'Authorization: Basic '.$auth));
    curl_setopt($ch, CURLOPT_USERAGENT, 'PHP-MCAPI/2.0');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $type );
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);   

    if( $data )curl_setopt( $ch, CURLOPT_POSTFIELDS, json_encode( $data ) );                                                                                                            

    $response = curl_exec($ch);
    curl_close($ch);

    $response = json_decode($response, true);

    return $response;
}

function mc_get( $api, $type, $target, $data = false ) {
    $auth = base64_encode( 'user:'.$apikey );

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $api['url'].$target);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json', 'Authorization: Basic '.$auth));
    curl_setopt($ch, CURLOPT_USERAGENT, 'PHP-MCAPI/2.0');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $type );
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);   

    if( $data )curl_setopt( $ch, CURLOPT_POSTFIELDS, json_encode( $data ) );                                                                                                            

    $response = curl_exec($ch);
    curl_close($ch);
    
    $response = json_decode($response, true);

    return $response;
}

function validateEmail( $email ) {
    // Check if email is present
    if ($email == "") {
      $response = "You must enter a valid email address.";
    } else {

      // Check if email format is valid
      if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $response = "You must enter a valid email address.";
      }

      // Check that email domain is valid
      $domain = substr(strrchr($email, "@"), 1);
      if ( !empty($domain) and !checkdnsrr($domain, 'MX')) {
        $response = "You must enter a valid email address.";
	  }
    }
    return $response;
}

// Check for content injection
function contentInjectCheck( $getVars ) {
    foreach( $getVars as $value ) {
      if ( !is_array($value) ) {
        if ( stripos($value,'Content-Type:') !== FALSE ) {
          $response = "<p>There was a problem with the information you entered.</p>";;
        }
      } else {
        if ( strposa('Content-Type:', $value) ) {
          $response .= "<p>There was a problem with the information you entered.</p>";
        }
      }
	}
    return $formMessages;
}


if($_GET['email'] && $_GET['field'] && $_GET['value'])
{
  $mcapi = array
  (
    'key'   => $apikey,
    'url'   => $apiurl
  );
  $email = $_GET['email'];
  $field = $_GET['field'];
  $value = $_GET['value'];

  $response = validateEmail($email);
  if($response != "") {goto reply;}
  $response = contentInjectCheck($_GET);
  if($response != "") {goto reply;}

  if(strpos($value, ",")!== false)
  {
    $raw = explode(",",$value);
  }
  
  if(count($raw)>0)
  {
    foreach ($raw as $x) {
      $codes[$x] = $x;
    }
	arsort($codes);
  }
  else
  {
    if($value!=""){$codes[$value] = $value;}
  }

//check whether this member is existing and then check for the signed up subject
///////////////////////////////////////////////////////////////
  $mctype = 'GET';
  $mctaget = 'lists/'.$listid.'/members/'.$email;
  $mcdata = array('apikey' => $mcapi['key']);
  $memberInfo = mc_get( $mcapi, $mctype, $mctaget, $mcdata );
  if($memberInfo['status']=="subscribed")
  {
    if($memberInfo["merge_fields"][$field]!="")
    {
	  $raw = explode(",",$memberInfo["merge_fields"][$field]);
      if(count($raw)>0)
      {
        foreach ($raw as $x) {
          $codes[$x] = $x;
        }
      }
	  $allcodes = "";
	  arsort($codes);
      foreach ($codes as $code => $code_value) {
        $allcodes .= $code;
		if($codes[array_key_last($codes)]!=$code)
		{$allcodes .= ",";}
      }
      $mergeFields = array($field => $allcodes);
    }
    else
    {
      $mergeFields = array($field => $value);
    }
    $mctaget .= "?skip_merge_validation=false";
    $mcdata = array(
      'apikey'        => $mcapi['key'],
      'email_address' => $email,
      'merge_fields'  => $mergeFields
      );
    //Update the subject in the mailchimp
    ///////////////////////////////////////////////////////////////
    $memberInfo = mc_request( $mcapi, 'PATCH', $mctaget, $mcdata );
    if($memberInfo['status']=="subscribed"){$response .= "Thank you for signing up the subject newsletter.";}
    else{$response = "Could not opt in this subject newsletter for you.";}
  }
  //ask the user to re-subscribe again if the status is unsubscribed
  ///////////////////////////////////////////////////////////////
  elseif($memberInfo['status']=="unsubscribed")
  {
	// Remember to fill in the XXXXXX with your signup/opt-in form url id
    $response = "You had unsubscribed before. Please <a href='http://eepurl.com/XXXXXX'>re-subscribe</a> now.";
  }
  //sign up the new user
  ///////////////////////////////////////////////////////////////
  elseif($memberInfo['status']=="404")
  {
	$mctaget = 'lists/'.$listid.'/members/';
	$mergeFields = array($field => $value);
    $mcdata = array(
        'apikey'        => $mcapi['key'],
        'email_address' => $email,
        'status'        => 'pending', // pending to trigger double opt in
        'merge_fields'  => $mergeFields
        );  
    $memberInfo = mc_request( $mcapi, 'POST', $mctaget, $mcdata );
    if($memberInfo['status']=="pending"){$response = "Thank you for signing up this subject newsletter. Please check your email and click on the link to confirm your sign up.";}
    else
	{
	  if( $memberInfo["title"]="Forgotten Email Not Subscribed"){$response = "You were unsubscribed by us before. Please <a href='http://eepurl.com/hKPPGT'>re-subscribe</a> now.";}
	  else
	  {
	    $response = "Could not sign up this subject newsletter for you. Please contact us @ <a href='mailto:XXX@XXX.com'>XXX@XXX.com</a>";
	  }
	}    
  }
  else
  {
    $response = "Please go to your email and click on the confirmation link.";
  }
}
else
{
  $response = "There is an error on the header while connecting to the server!";
}

reply:
echo 'jsonCallback({"response":"'.$response.'"})';

?>