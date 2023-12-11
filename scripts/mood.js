const tokenUri = args[0];

const response = await fetch(tokenUri);
const data = await response.json();

if (data && data.properties && data.properties.text && data.properties.text.description) {
    const diaryText = data.properties.text.description;
} else {
    return null;
}
