(function(){var c=window.CAMPUS_CONFIG||{};
document.querySelectorAll("[data-cfg]").forEach(function(e){var k=e.getAttribute("data-cfg"),v=c[k];
 if(v){e.textContent=v;e.classList.remove("missing");if(e.tagName==="A"){e.href=(k==="CONTACT_EMAIL"?"mailto:":k==="CONTACT_PHONE"?"tel:":"#")+v}}else{e.classList.add("missing")}})})();
