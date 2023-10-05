<div class='box'>
<div style='display:flex; align-items:center; gap:1em;'>
   <div><h2>{php}echo _tr('Progress');{/php}</h2></div>
   <div id='loader'><i class="fa fa-spinner fa-spin" style='font-size:2.5em; color: orange;'></i></div>
   <div class="checkwrapper" id="check"><svg class="checkmark" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 52"> <circle class="checkmark__circle" cx="26" cy="26" r="25" fill="none"/> <path class="checkmark__check" fill="none" d="M14.1 27.2l7.1 7.2 16.7-16.8"/></svg></div>
</div>
<div style='padding-top:2em;'>
<iframe name="ifm" id="myframe" frameborder=0 width="100%" height="500px" marginheight=0 marginwidth=0 scrolling=yes src={$frame_url}></iframe>
</div>
</div>
<script>
pepe = setInterval('frames[0].scrollTo(0,9999999)',1000);
</script>
