if (window.localStorage.getItem('logout') != null) {
    window.localStorage.removeItem('logout');
    setTimeout(function() { window.location.href = window.location.origin; }, 100);
}else{
    var checkFormInterval = setInterval(function() {
        if (document.getElementsByClassName('external-login').length) {
            clearInterval(checkFormInterval);
            document.getElementById('login-card').getElementsByClassName('external-login')[0].click();
        }  }, 100);
}