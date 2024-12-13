<script type="text/javascript">
    $(document).ready(function() {
        $(document).on('keydown', function(e) {
            if (e.key === 'Enter') { // Check if the Enter key is pressed
                console.log('enter key triggered');
                if ($(document.activeElement).hasClass('btn')) {
                    console.log('triggering click', document.activeElement);
                    $(document.activeElement).trigger('click');
                    e.preventDefault();
                }
            }
        });
    });
</script>
