$(document).ready(function() {
    var container = $('#container');
    var mainMenu = $('#main-menu');

    $.waypoints.settings.scrollThrottle = 30;
    mainMenu.waypoint(function(event, direction) {
        container.toggleClass('sticky', direction === "down");
        event.stopPropagation();
    }, { offset: 0 });

    // Register each article as a waypoint.
    $('#main article').waypoint({ offset: '50%' });

    // The same for all waypoints
    container.delegate('#main article', 'waypoint.reached', function(event, direction) {
        var $active = $(this);

        if (direction === "up") {
            $active = $active.prev();
        }
        if (!$active.length) $active.end();

        $('.current', mainMenu).removeClass('current');
        $('a[href="#' + $active.attr('id') + '"]', mainMenu).parent().addClass('current');
    });

    $('a', mainMenu).click(function() {
        $(this).addClass('current');
    }).eq(0).addClass('current');

    // Wicked credit to
    // http://www.zachstronaut.com/posts/2009/01/18/jquery-smooth-scroll-bugs.html
    var scrollElement = 'html, body';
    $('html, body').each(function () {
        var initScrollTop = $(this).attr('scrollTop');
        $(this).attr('scrollTop', initScrollTop + 1);
        if ($(this).attr('scrollTop') == initScrollTop + 1) {
            scrollElement = this.nodeName.toLowerCase();
            $(this).attr('scrollTop', initScrollTop);
            return false;
        }
    });

    // Smooth scrolling for internal links
    $("a[href^='#']").click(function(event) {
        event.preventDefault();

        var $this = $(this),
        target = this.hash,
        $target = $(target);

        $(scrollElement).stop().animate({
            'scrollTop': $target.offset().top
        }, 500, 'swing', function() {
            window.location.hash = target;
        });

    });});
