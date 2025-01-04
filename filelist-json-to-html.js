
    // Fetch JSON data
    fetch('file-index-html.json')
        .then(response => response.json())
        .then(data => {
            // Populate metadata
            const metaContent = document.getElementById('metadata-content');
            const metaDescriptions = data.meta.descriptions;
            const metaValues = data.meta.values;

            let metadataHTML = '<ul>';
            for (let key in metaDescriptions) {
                metadataHTML += `
                    <li>
                        <strong>${metaDescriptions[key]}:</strong> ${metaValues[key]}
                    </li>`;
            }
            metadataHTML += '</ul>';
            metaContent.innerHTML = metadataHTML;

            // Populate directory dropdown
            const directorySelect = document.getElementById('directory-select');
            const directories = [...new Set(data.fileinfo.map(file => file.directory))];
            directories.forEach(directory => {
                const option = document.createElement('option');
                option.value = directory;
                option.textContent = directory;
                directorySelect.appendChild(option);
            });

            // Handle directory selection
            const fileList = document.getElementById('file-list');
            const sortOrderSelect = document.getElementById('sort-order');

            const renderFiles = (selectedDir, sortOrder) => {
                fileList.innerHTML = ''; // Clear previous files
                let files = data.fileinfo.filter(file => file.directory === selectedDir);

                // Sort files by last_modified
                files.sort((a, b) => {
                    const dateA = new Date(a.last_modified);
                    const dateB = new Date(b.last_modified);
                    return sortOrder === 'asc' ? dateA - dateB : dateB - dateA;
                });

                files.forEach(file => {
                    const listItem = document.createElement('li');
                    listItem.innerHTML = `
                        <span class="datum">${file.last_modified}</span>
                        <span class="dir">${file.directory}</span>
                        <a href="${file.relative_path}" target="_blank">${file.filename}</a>`;
                    fileList.appendChild(listItem);
                });
            };

            directorySelect.addEventListener('change', () => {
                const selectedDir = directorySelect.value;
                const sortOrder = sortOrderSelect.value;
                renderFiles(selectedDir, sortOrder);
            });

            sortOrderSelect.addEventListener('change', () => {
                const selectedDir = directorySelect.value;
                const sortOrder = sortOrderSelect.value;
                if (selectedDir) {
                    renderFiles(selectedDir, sortOrder);
                }
            });
        })
        .catch(error => console.error('Error loading JSON:', error));
