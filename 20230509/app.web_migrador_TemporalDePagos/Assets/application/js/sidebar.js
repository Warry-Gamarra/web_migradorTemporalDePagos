
$('.hdn-sidebar').on('click', function () {
    ShowSidebar();
});

$('#toggle-menu').on('click', function () {
    ShowSidebar();
});

function ShowSidebar() {
    if ($(window).width() > (768)) {
        if ($("body").hasClass('sidebar-collapse')) {
            $("body").removeClass('sidebar-collapse');
        } else {
            $("body").addClass('sidebar-collapse');
        }
    }
    else {
        if ($("body").hasClass('sidebar-open')) {
            $("body").removeClass('sidebar-open').removeClass('sidebar-collapse');
        } else {
            $("body").addClass('sidebar-open');
        }
    }
}

