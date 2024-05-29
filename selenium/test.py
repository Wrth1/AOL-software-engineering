from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Create webdriver object
driver = webdriver.Firefox()

# Get the webpage
driver.get("https://notetestlol.web.app/")

# Explicit wait
wait = WebDriverWait(driver, 20)

# Find the element using a more specific CSS selector
try:
    element = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "input.flt-text-editing")))
    element.send_keys("Hello World")
except Exception as e:
    print(f"An error occurred: {e}")

# Close the browser
driver.quit()
