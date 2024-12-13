// comment: In Rock v16+ the Select button on the person picker can no longer be activated by the Enter key, adding this js to the footer of the page will make it work 

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
