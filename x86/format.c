#include	<stdio.h>

int	main(void){
	FILE		*file;
	unsigned char	entry[16]={0x80, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1};

	if((file = fopen("disk", "rb+"))==NULL){
		printf("Error: Can not open \"disk\"!\n");
		return 1;
	}

	fseek(file, 0x01BE, SEEK_SET);
	fwrite(&entry, 1, 16, file);

	fclose(file);

	return 0;
}
